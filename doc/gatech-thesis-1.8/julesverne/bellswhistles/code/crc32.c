// Calculate a CRC 32 checksum.

#include <malloc.h>
#include <stdio.h>

// LAST MODIFIED:[7-28-93]

// Usage:
// unsigned long crc = -1L
// crc = crc32(buffer, length, crc)

unsigned long crc32 (void *buffer, unsigned int count, unsigned long crc);
static int BuildCRCTable (void);

static unsigned long *CRCTable; // Table constructed for fast lookup.

#define CRC32_POLYNOMIAL	0xEDB88320L

// Initialize the CRC calculation table
//
static int
BuildCRCTable (void)
{
  int i, j;
  unsigned long crc;

  CRCTable = malloc (256 * sizeof (unsigned long));
  if (CRCTable == NULL)
    {
      fprintf (stderr, "Can't malloc space for CRC table in file %s\n",
               __FILE__);
      return -1L;
    }

  for (i = 0; i <= 255; i++)
    {
      crc = i;
      for (j = 8; j > 0; j--)
        if (crc & 1)
          crc = (crc >> 1) ^ CRC32_POLYNOMIAL;
        else
          crc >>= 1;
      CRCTable[i] = crc;
    }
  return 0;
}

unsigned long
crc32 (void *buffer, unsigned int count, unsigned long crc)
{
  unsigned long temp1, temp2;
  static int firsttime = 1;
  unsigned char *p = (unsigned char *) buffer;

  if (firsttime)
    {
      if (BuildCRCTable ())
        return -1;
      firsttime = 0;
    }

  while (count-- != 0)
    {
      temp1 = (crc >> 8) & 0x00FFFFFFL;
      temp2 = CRCTable[((int) crc ^ *p++) & 0xFF];
      crc = temp1 ^ temp2;
    }
  return crc;
}
