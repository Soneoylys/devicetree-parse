/*
 * devicetree-parse.c
 * Brandon Azad
 */
#include "devicetree-parse.h"

#include <assert.h>
#include <stdio.h>

struct devicetree_node {
	uint32_t n_properties;
	uint32_t n_children;
};

struct devicetree_property {
	char name[32];
	uint16_t size;
	uint16_t flags;
	uint8_t data[0];
};

static bool
devicetree_iterate_node(const void **data, const void *data_end,
		unsigned depth, bool *stop,
		devicetree_iterate_node_callback_t node_callback,
		devicetree_iterate_property_callback_t property_callback,
		void *ctx) {
	assert(!*stop);
	const uint8_t *p = *data;
	const uint8_t *end = (const uint8_t *)data_end;
	struct devicetree_node *node = (struct devicetree_node *)p;
	p += sizeof(*node);
	if (p > end) {
		return false;
	}
	uint32_t n_properties = node->n_properties;
	uint32_t n_children   = node->n_children;
	if (node_callback != NULL) {
		node_callback(depth, (const void *)node, end - p + sizeof(*node),
				n_properties, n_children, stop, ctx);
		if (*stop) {
			return true;
		}
	}
	for (size_t i = 0; i < n_properties; i++) {
		struct devicetree_property *prop = (struct devicetree_property *)p;
		p += sizeof(*prop);
		if (p > end) {
			return false;
		}
		if (prop->name[sizeof(prop->name) - 1] != 0) {
			return false;
		}
		uint32_t prop_size = prop->size;
		size_t padded_size = (prop_size + 0x3) & ~0x3;
		p += padded_size;
		if (p > end) {
			if (p - padded_size + prop_size == end) {
				p = end;
			} else {
				return false;
			}
		}
		if (property_callback != NULL) {
			property_callback(depth + 1, prop->name, prop->data, prop_size, prop->flags, stop,
					ctx);
			if (*stop) {
				return true;
			}
		}
	}
	*data = p;
	for (size_t i = 0; i < n_children; i++) {
		bool ok = devicetree_iterate_node(data, end, depth + 1, stop,
				node_callback, property_callback, ctx);
		if (!ok) {
			return false;
		}
		if (*stop) {
			return true;
		}
	}
	if (node_callback != NULL) {
		node_callback(depth, NULL, 0, 0, 0, NULL, ctx);
	}
	return true;
}

bool
devicetree_iterate(const void **data, size_t size,
		devicetree_iterate_node_callback_t node_callback,
		devicetree_iterate_property_callback_t property_callback,
		void *ctx) {
	const void *end = (const uint8_t *)*data + size;
	bool stop = false;
	return devicetree_iterate_node(data, end, 0, &stop, node_callback, property_callback, ctx);
}

static void
stop_on_child_node(unsigned depth, const void *node, size_t size,
		unsigned n_properties, unsigned n_children, bool *stop, void *ctx) {
	(void)node;
	(void)size;
	(void)n_properties;
	(void)n_children;
	(void)ctx;
	if (depth != 0) {
		*stop = true;
	}
}

bool
devicetree_node_scan_properties(const void *node, size_t size,
		devicetree_iterate_property_callback_t property_callback,
		void *ctx) {
	return devicetree_iterate(&node, size, stop_on_child_node, property_callback, ctx);
}
