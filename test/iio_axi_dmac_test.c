/*
 * Inspired by - ADI AXI DMA IIO streaming example
 *
 **/

#include <getopt.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <signal.h>
#include <stdio.h>
#include <iio.h>
#include <unistd.h>
#include <errno.h>

#define IIO_ENSURE(expr) { \
	if (!(expr)) { \
		(void) fprintf(stderr, "assertion failed (%s:%d)\n", __FILE__, __LINE__); \
		(void) abort(); \
	} \
}

static const struct option options[] = {
	{"help", no_argument, 0, 'h'},
	{"buffer-size", required_argument, 0, 's'},
	{"iio-device-name", required_argument, 0, 'd'},
	{0, 0, 0, 0},
};

static const char *options_descriptions[] = {
	"Show this help and quit.",
	"Size of the buffer. Default is 1M byte and is loaded with count from 1.",
	"Recreate DMA buffer before push or refill.",
	"IIO device name."
};

static void usage(char *argv[])
{
	unsigned int i;

	printf("Usage:\n\t%s [-s <size>] <iio_device>\n\nOptions:\n", argv[0]);
	for (i = 0; options[i].name; i++)
		printf("\t-%c, --%s\n\t\t\t%s\n",
		       options[i].val, options[i].name,
	 options_descriptions[i]);
}

/* IIO structs required for streaming */
static struct iio_context *ctx = NULL;
static struct iio_channel *dma_chan = NULL;
static struct iio_buffer *dma_buffer = NULL;

static bool stop = false;

/* cleanup and exit */
void shutdown()
{
	printf("* Destroying buffer\n");
	if (dma_buffer)
		iio_buffer_destroy(dma_buffer);

	printf("* Disabling streaming channel\n");
	if (dma_chan)
		iio_channel_disable(dma_chan);

	printf("* Destroying context\n");
	if (ctx)
		iio_context_destroy(ctx);

	exit(0);
}

static void handle_sig(int sig)
{
	printf("Waiting for process to finish... Got signal %d\n", sig);
	stop = true;
}

void pbuf(const char *pref, const struct iio_buffer *dma_buffer)
{
	if ((pref == NULL) || (dma_buffer == NULL))
		return;

	void *p_dat = NULL;
	void *p_end = iio_buffer_end(dma_buffer);
	ptrdiff_t p_inc = iio_buffer_step(dma_buffer);

	printf("%s", pref);
	for (p_dat = iio_buffer_first(dma_buffer, dma_chan); p_dat < p_end; p_dat += p_inc)
		printf("0x%08jx ", *(uint64_t *)p_dat);
	printf("\n");
}

/* simple configuration and streaming */
int main (int argc, char **argv)
{
	char err_str[512];
	int nbytes = 0;
	void *p_dat = NULL;
	void *p_end = NULL;
	ptrdiff_t p_inc = 0;
	uint64_t n = 0;
	char sbuf[16];

	struct iio_device *dev = NULL;
	char *dev_name = NULL;
	unsigned int buffer_size = 1024 * 1024;
	unsigned int i = 0;
	bool device_is_tx = false;
	bool timeout = false;
	int option_index = 0;
	int arg_index = 0;
	char unit;
	int ret = 0;

	while ((i = getopt_long(argc, argv, "d:s:rh", options, &option_index)) != -1) {
		switch (i) {
			case 'd':
				dev_name = optarg;
				break;
			case 's':
				ret = sscanf(optarg, "%d%c", &buffer_size, &unit);
				if (ret == 0)
					return EXIT_FAILURE;
				if (ret == 2) {
					if (unit == 'k')
						buffer_size *= 1024;
					else if (unit == 'M')
						buffer_size *= 1024 * 1024;
				}
				break;
			case 'h':
			default:
				usage(argv);
				return EXIT_SUCCESS;
		}
	}

	if (arg_index + 1 >= argc) {
		fprintf(stderr, "Incorrect number of arguments.\n\n");
		usage(argv);
		return EXIT_FAILURE;
	}

	// Listen to ctrl+c and assert
	signal(SIGINT, handle_sig);

	IIO_ENSURE((ctx = iio_create_default_context()) && "No context");
	IIO_ENSURE(iio_context_get_devices_count(ctx) > 0 && "No devices");
	IIO_ENSURE((dev = iio_context_find_device(ctx, dev_name)) && "No streaming device found");
	IIO_ENSURE(iio_device_get_channels_count(dev) == 1 && "No channels");
	IIO_ENSURE((dma_chan = iio_device_get_channel(dev, 0)) && "No channel");
	IIO_ENSURE(iio_channel_is_scan_element(dma_chan) && "No streaming capabilities");

	iio_channel_enable(dma_chan);

	IIO_ENSURE((dma_buffer = iio_device_create_buffer(dev, buffer_size, false)) && "Failed to create buffer");

	printf("Performing data transfer. Ctrl + c to terminate.\n");

	device_is_tx = iio_channel_is_output(dma_chan);
	while (!stop) {
		if (device_is_tx) {
			if (!timeout) {
				p_inc = iio_buffer_step(dma_buffer);
				p_end = iio_buffer_end(dma_buffer);
				for (p_dat = iio_buffer_first(dma_buffer, dma_chan); p_dat < p_end; p_dat += p_inc)
					*(uint64_t *)p_dat = ++n;

				pbuf("$ TX: ", dma_buffer);
			}

			nbytes = iio_buffer_push(dma_buffer);
			if (nbytes < 0) {
				iio_strerror(-nbytes, err_str, sizeof(err_str));
				printf("* Error pushing buffer %d: %s\n", nbytes, err_str);
				if (nbytes == -ETIMEDOUT) {
					printf("* Ensure that transmit buffer is getting emptied. Run RX first if in loopback.");
					if (!timeout)
						timeout = true;

					continue;
				}

				shutdown();
				break;
			}

			if (timeout)
				timeout = false;
		} else {
			nbytes = iio_buffer_refill(dma_buffer);
			if (nbytes < 0) {
				iio_strerror(-nbytes, err_str, sizeof(err_str));
				printf("* Error refilling buffer %d: %s\n", nbytes, err_str);
				if (nbytes == -ETIMEDOUT) {
					printf("* Ensure that receive buffer is getting filled in PL. Run TX if in loopback.");
					if (!timeout)
						timeout = true;

					continue;
				}

				shutdown();
				break;
			}

			if (timeout)
				timeout = false;

			(void)snprintf(sbuf, sizeof(sbuf), "$ RX (%d): ", nbytes);
			pbuf(sbuf, dma_buffer);
		}
	}

	shutdown();

	return 0;
}
