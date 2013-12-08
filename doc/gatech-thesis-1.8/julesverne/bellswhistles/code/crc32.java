/**
 * This program reads a file and generates the checksum.
 * The CheckedInputStream class is an example of the Strategy pattern
 *
 * @author Greg Gagne - May 2001
 */
import java.io.*;
import java.util.zip.*;

public class CheckSum
{
  public static void main (String[]args) throws IOException
  {
    CheckedInputStream inFile = null;

    // generate the checksum using the CRC32 algorithm
    Checksum cs = new CRC32 ();

    // check for necessary parameters
    if (args.length != 1)
      {
        System.err.println ("Usage: CheckSum <input file>");
        System.exit (0);
      }
    else
      {
        try
        {
          inFile = new CheckedInputStream (new FileInputStream (args[0]), cs);
          int data;
          while ((data = inFile.read ()) != -1)
             ;
        }
        catch (FileNotFoundException fnfe)
        {
          System.err.println ("File " + args[0] + " not found.");
        }
        finally
        {
          if (inFile != null)
            inFile.close ();
        }

        System.out.println ("The checksum of the input file is " +
                            inFile.getChecksum ().getValue ());
      }
  }
}
