/*
 * Inspired by - ADI AXI DMA IIO streaming example
 *
 **/

#include <errno.h>
#include <getopt.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <iio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

static const struct option options[] = {
	{"help", no_argument, 0, 'h'},
	{"buffer-size", required_argument, 0, 's'},
	{0, 0, 0, 0},
};

static const char *options_descriptions[] = {
	"Show this help and quit.",
	"Size of the buffer. Default is 1M byte and is loaded with count from 1.",
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
static struct iio_context *ctx   = NULL;
static struct iio_channel *dma_chan = NULL;
static struct iio_buffer  *dma_buffer = NULL;

/* cleanup and exit */
void shutdown(int s)
{
	printf("* Destroying buffers\n");

	if (dma_buffer)
		iio_buffer_destroy(dma_buffer);

	printf("* Disabling streaming channels\n");

	if (dma_chan)
		iio_channel_disable(dma_chan);

	printf("* Destroying context\n");
	if (ctx)
		iio_context_destroy(ctx);

	exit(0);
}

/* simple configuration and streaming */
int main (int argc, char **argv)
{
	size_t nbytes_rx;
	size_t nbytes_tx;
	void *p_dat;
	void *p_end;
	ptrdiff_t p_inc;

	struct iio_device *dev;
	const char *device_name;
	unsigned int buffer_size = 1024 * 1024;
	unsigned int i;
	uint64_t *work_buffer;
	uint64_t *buf;
	bool device_is_tx = false;
	unsigned int nb_channels;
	unsigned int n_tx = 0;
	unsigned int n_rx = 0;

	int c;
	int option_index = 0;
	int arg_index = 0;
	char unit;
	int ret;

	while ((c = getopt_long(argc, argv, "+hs:",
		options, &option_index)) != -1) {
		switch (c) {
			case 'h':
				usage(argv);
				return EXIT_SUCCESS;
			case 's':
				arg_index += 2;
				ret = sscanf(argv[arg_index], "%d%c", &buffer_size, &unit);
				if (ret == 0)
					return EXIT_FAILURE;
				if (ret == 2) {
					if (unit == 'k')
						buffer_size *= 1024;
					else if (unit == 'M')
						buffer_size *= 1024 * 1024;
				}
				break;
			case '?':
				return EXIT_FAILURE;
		}
	}

	if (arg_index + 1 >= argc) {
		fprintf(stderr, "Incorrect number of arguments.\n\n");
		usage(argv);
		return EXIT_FAILURE;
	}

	// Listen to ctrl+c and assert
	signal(SIGINT, shutdown);

	ctx = iio_create_default_context();

	if (!ctx) {
		fprintf(stderr, "Unable to create IIO context\n");
		return EXIT_FAILURE;
	}

	device_name = argv[arg_index + 1];
	dev = iio_context_find_device(ctx, device_name);

	if (!dev) {
		fprintf(stderr, "Device %s not found\n", device_name);
		shutdown(0);
	}

	nb_channels = iio_device_get_channels_count(dev);

	for (i = 0; i < nb_channels; i++) {
		struct iio_channel *ch = iio_device_get_channel(dev, i);

		if (!iio_channel_is_scan_element(ch))
			continue;

		iio_channel_enable(ch);

		if (iio_channel_is_output(ch)) {
			dma_chan = ch;
			n_tx++;
		} else {
			dma_chan = ch;
			n_rx++;
		}
	}

	if (n_tx >= n_rx)
		device_is_tx = true;
	else
		device_is_tx = false;

	work_buffer = malloc(buffer_size * sizeof(uint64_t));

	for (i = 0; i < buffer_size; i++)
		work_buffer[i] = i + 1;

	i = 0;

	while(!dma_buffer) {
		dma_buffer = iio_device_create_buffer(dev, buffer_size, false);

		if (!dma_buffer)
			printf("* BUG: iio_device_create_buffer(...) returns NULL %d time(s)\n", ++i);
	}

	if (device_is_tx) {
		p_inc = iio_buffer_step(dma_buffer);
		p_end = iio_buffer_end(dma_buffer);
		buf   = iio_buffer_start(dma_buffer);

		while(!buf) {
			perror("* BUG: Could not get iio buffer start");
			buf = iio_buffer_start(dma_buffer);
		}

		memcpy(buf, work_buffer, buffer_size * sizeof(uint64_t));

		printf("* TX: ");

		for (p_dat = buf; p_dat < p_end; p_dat += p_inc)
			printf("0x%jx ", *((uint64_t *)p_dat));

		printf("\n");
	} else {
		memset(work_buffer, 0, buffer_size * sizeof(uint64_t));
	}

	printf("Performing data transfer. Ctrl + c to terminate.\n");

	while (1) {
		// Schedule TX buffer
		if (device_is_tx) {
			nbytes_tx = iio_buffer_push(dma_buffer);

			if (nbytes_tx < 0)
				printf("* Error pushing dma buffer %d\n", (int) nbytes_tx);
		} else {
			nbytes_rx = iio_buffer_refill(dma_buffer);

			if (nbytes_rx < 0) {
				printf("* Error refilling dma buffer %d\n", (int) nbytes_rx);
			} else {
				p_inc = iio_buffer_step(dma_buffer);
				p_end = iio_buffer_end(dma_buffer);

				buf = iio_buffer_start(dma_buffer);

				while(!buf) {
					perror("* BUG: Could not get iio buffer start");
					buf = iio_buffer_start(dma_buffer);
				}

				//printf("* RX (%d): ", (int) nbytes_rx);

				//for (p_dat = iio_buffer_first(dma_buffer, dma_chan); p_dat < p_end; p_dat += p_inc)
				//	printf("0x%jx ", *((uint64_t *)p_dat));

				//printf("\n");
			}
		}
	}

	shutdown(0);

	return 0;
}
