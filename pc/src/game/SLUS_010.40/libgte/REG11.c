#include "common.h"
#include <libgte.h>

/* The far colour: nothing keeps it. The map's DpqColor fades toward black through vs_gte_dpcs (MENU5 4D8.c), which takes the
 * far colour as an argument. */
void SetFarColor(long rfc, long gfc, long bfc)
{
    (void)rfc;
    (void)gfc;
    (void)bfc;
}
