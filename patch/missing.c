#include <neo4j-client.h>
#include <assert.h>
#include <errno.h>
#include <limits.h>
#include <stddef.h>
#include "../include/values.h"
// this code is lifted from
// https://github.com/cleishm/libneo4j-client/blob/master/lib/src/values.c
size_t neo4j_node_str(const neo4j_value_t *value, char *buf, size_t n);
ssize_t neo4j_node_fprint(const neo4j_value_t *value, FILE *stream);
size_t neo4j_rel_str(const neo4j_value_t *value, char *buf, size_t n);
ssize_t neo4j_rel_fprint(const neo4j_value_t *value, FILE *stream);

static struct neo4j_value_vt node_vt =
    { .str = neo4j_node_str,
      .fprint = neo4j_node_fprint,
      .serialize = neo4j_struct_serialize,
      .eq = struct_eq };
static struct neo4j_value_vt relationship_vt =
    { .str = neo4j_rel_str,
      .fprint = neo4j_rel_fprint,
      .serialize = neo4j_struct_serialize,
      .eq = struct_eq };
struct neo4j_value_vts
{
    const struct neo4j_value_vt *node_vt;
    const struct neo4j_value_vt *relationship_vt;
};
static const struct neo4j_value_vts neo4j_value_vts =
{
    .node_vt = &node_vt,
    .relationship_vt = &relationship_vt,
};
#define VT_OFFSET(name) \
        (offsetof(struct neo4j_value_vts, name) / sizeof(struct neo4j_value_vts *))
neo4j_value_t neo4j_node(const neo4j_value_t fields[3])
{
    if (neo4j_type(fields[0]) != NEO4J_IDENTITY ||
            neo4j_type(fields[1]) != NEO4J_LIST ||
            neo4j_type(fields[2]) != NEO4J_MAP)
    {
        errno = EINVAL;
        return neo4j_null;
    }
    const struct neo4j_list *labels = (const struct neo4j_list *)&(fields[1]);
    for (unsigned int i = 0; i < labels->length; ++i)
    {
        if (neo4j_type(labels->items[i]) != NEO4J_STRING)
        {
            errno = NEO4J_INVALID_LABEL_TYPE;
            return neo4j_null;
        }
    }

    struct neo4j_struct v =
            { ._type = NEO4J_NODE, ._vt_off = NODE_VT_OFF,
              .signature = NEO4J_NODE_SIGNATURE,
              .fields = fields, .nfields = 3 };
    return *((neo4j_value_t *)(&v));
}

neo4j_value_t neo4j_relationship(const neo4j_value_t fields[5])
{
    if (neo4j_type(fields[0]) != NEO4J_IDENTITY ||
            (neo4j_type(fields[1]) != NEO4J_IDENTITY &&
                !neo4j_is_null(fields[1])) ||
            (neo4j_type(fields[2]) != NEO4J_IDENTITY &&
                !neo4j_is_null(fields[1])) ||
            neo4j_type(fields[3]) != NEO4J_STRING ||
            neo4j_type(fields[4]) != NEO4J_MAP)
    {
        errno = EINVAL;
        return neo4j_null;
    }

    struct neo4j_struct v =
            { ._type = NEO4J_RELATIONSHIP, ._vt_off = RELATIONSHIP_VT_OFF,
              .signature = NEO4J_REL_SIGNATURE,
              .fields = fields, .nfields = 5 };
    return *((neo4j_value_t *)(&v));
}

neo4j_value_t neo4j_node_identity(neo4j_value_t value)
{
    REQUIRE(neo4j_type(value) == NEO4J_NODE, neo4j_null);
    const struct neo4j_struct *v = (const struct neo4j_struct *)&value;
    assert(v->nfields == 3);
    assert(neo4j_type(v->fields[0]) == NEO4J_IDENTITY);
    return v->fields[0];
}

