using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using System.Xml.Serialization;

namespace MTFCalculator
{
    public partial class MTFCalculatorForm : Form
    {
        Bitmap bitmap = null;

        private string filename = string.Empty;

        public string Status
        {
            get 
            {
                return toolStripStatusLabel.Text;
            }
            set 
            {
                toolStripStatusLabel.Text = value;
                toolStripStatusLabel.Invalidate();
            }
        }

        private ImagePanel imagePanel = new ImagePanel();

        private GraphPanel graphPanelLSF = new GraphPanel();

        private GraphPanel graphPanelMTF = new GraphPanel();

        private AboutForm aboutForm = new AboutForm();

        private Options options = new Options();

        private OptionsForm optionsForm = new OptionsForm();

        public MTFCalculatorForm()
        {
            InitializeComponent();

            string directory = System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData);

            if (System.IO.File.Exists(directory + "\\" + Resource.OptionsFileName))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(Options));

                try
                {
                    using (System.IO.Stream stream = System.IO.File.OpenRead(directory + "\\" + Resource.OptionsFileName))
                    {
                        options = (Options)serializer.Deserialize(stream);
                    }
                }
                catch
                {
                    MessageBox.Show("There was a problem deserializing MTFCalculator.xml.  Using the default options.", 
                        Resource.MessageBoxCaption);
                }
            }

            aboutForm.Owner = this;

            optionsForm.Owner                       = this;
            optionsForm.PropertyGrid.SelectedObject = options;

            graphPanelLSF.BackColor   = Color.White;
            graphPanelLSF.BorderStyle = BorderStyle.None;
            graphPanelLSF.Dock        = DockStyle.Fill;

            tabLSF.Controls.Add(graphPanelLSF);

            graphPanelMTF.BackColor   = Color.White;
            graphPanelMTF.BorderStyle = BorderStyle.None;
            graphPanelMTF.Dock        = DockStyle.Fill;

            tabMTF.Controls.Add(graphPanelMTF);

            imagePanel.BackColor    = Color.White;
            imagePanel.BorderStyle  = BorderStyle.None;
            imagePanel.Dock         = DockStyle.Fill;

            tabImage.Controls.Add(imagePanel);

            toolStripStatusLabel.Text = "Open an image to calculate the Modulation Transfer Function.";
        }

        private void Save()
        {
            System.IO.StreamWriter writer = new System.IO.StreamWriter(filename);

            if (writer != null)
            {
                string s = options.XLabel;

                if (graphPanelMTF.XUnits != string.Empty)
                {
                    s += " ( " + graphPanelMTF.XUnits + " )";
                }

                s += "," + options.YLabel;

                if (graphPanelMTF.YUnits != string.Empty)
                {
                    s += " ( " + graphPanelMTF.YUnits + " )";
                }

                s += "\n";

                for (int i = 0; i < graphPanelMTF.X.Length; i++)
                {
                    s += graphPanelMTF.X[i].ToString() + "," + graphPanelMTF.Y[i].ToString() + "\n";
                }

                writer.Write(s);
                writer.Close();
            }
        }

        /// <summary>
        /// Single-frequency sinusoid.
        /// </summary>
        private void TestA()
        {
            int n = 256;

            double[] real = new double[n];
            double[] imag = new double[n];

            for (int i = 0; i < n; i++)
            {
                real[i] = Math.Sin((double)(i) / 2);
                imag[i] = 0.0;
            }

            MTF.HannWindow(real);

            double[] padded = MTF.ZeroPad(real);

            MTF.Compute(padded);

            double[] m = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                m[i] = padded[i];
            }

            graphPanelMTF.Y   = m;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, (float)(Math.PI), n / 4);
        }

        /// <summary>
        /// Ideal Line Spread Function (LSF).
        /// </summary>
        private void TestB()
        {
            int n = 128;

            double[] real = new double[n];
            double[] imag = new double[n];

            for (int i = 0; i < n; i++)
            {
                if (i == 64)
                {
                    real[i] = 1.0;
                }
                else
                {
                    real[i] = 0.0;
                }

                imag[i] = 0.0;
            }

            MTF.HannWindow(real);

            double[] padded = MTF.ZeroPad(real);

            MTF.Compute(padded);

            double[] m = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                m[i] = padded[i];
            }

            graphPanelMTF.Y   = m;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, 1.0f, 1.2f);
        }

        /// <summary>
        /// Non-ideal Line Spread Function (LSF).
        /// </summary>
        private void TestC()
        {
            int n = 128;

            double[] real = new double[n];
            double[] imag = new double[n];

            for (int i = 0; i < n; i++)
            {
                if (i == 63)
                {
                    real[i] = 0.5;
                }
                else if (i == 64)
                {
                    real[i] = 1.0;
                }
                else if (i == 65)
                {
                    real[i] = 0.5;
                }
                else
                {
                    real[i] = 0.0;
                }

                imag[i] = 0.0;
            }

            MTF.HannWindow(real);

            double[] padded = MTF.ZeroPad(real);

            MTF.Compute(padded);

            double[] m = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                m[i] = padded[i];
            }

            graphPanelMTF.Y   = m;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, 1.0f, 2.2f);
        }

        /// <summary>
        /// Conversion of a step response to a Line Spread Function (LSF).
        /// </summary>
        private void TestD()
        {
            int n = 256;
            int m = 8;

            double[] real = new double[n];
            double[] imag = new double[n];

            for (int i = 0; i < n; i++)
            {
                if (i < n / 2 - m / 2)
                {
                    real[i] = 1.0;
                }
                else if (i >= n / 2 - m / 2 && i <= n / 2 + m / 2)
                {
                    real[i] = 0.5 + 0.5 * Math.Cos(2 * Math.PI * ((double)(i - n / 2 + m / 2) / (2 * m)));
                }
                else
                {
                    real[i] = 0.0;
                }

                imag[i] = 0.0;
            }

            // Calculate the discrete derivative of the step response in real.

            double[] difference = new double[n];

            for (int i = 0; i < n - 1; i++)
            {
                difference[i] = real[i] - real[i + 1];
            }

            // Use the discrete derivative, which is the LSF, to compute the MTF.

            MTF.HannWindow(difference);

            double[] padded = MTF.ZeroPad(difference);

            MTF.Compute(padded);

            double[] mtf = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                mtf[i] = padded[i];
            }

            graphPanelMTF.Y   = mtf;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, 8.0f, 1.0f);
        }

        /// <summary>
        /// Load an image and display the MTF.
        /// </summary>
        private void TestE()
        {
            OpenFileDialog dialog = new OpenFileDialog();

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                Image image = Bitmap.FromFile(dialog.FileName);

                if (image != null)
                {
                    double[] real = new double[image.Width];

                    for (int i = 0; i < image.Width; i++)
                    {
                        real[i] = 0.0;

                        for (int j = 0; j < image.Height; j++)
                        {
                            real[i] += (image as Bitmap).GetPixel(i, j).GetBrightness() / image.Height;
                        }
                    }

                    double[] difference = new double[image.Width];

                    for (int i = 0; i < image.Width - 1; i++)
                    {
                        difference[i] = real[i] - real[i + 1];
                    }

                    // Use the discrete derivative, which is the LSF, to compute the MTF.

                    MTF.HannWindow(difference);

                    double[] padded = MTF.ZeroPad(difference);

                    MTF.Compute(padded);

                    graphPanelMTF.Y = new double[padded.Length / 2];

                    for (int i = 0; i < padded.Length / 2; i++)
                    {
                        graphPanelMTF.Y[i] = padded[i];
                    }

                    double pixelWidth        = 0.1;                 // mm
                    double samplingFrequency = 1 / pixelWidth;      // cycles / mm

                    graphPanelMTF.X = new double[padded.Length / 2];

                    for (int i = 0; i < padded.Length / 2; i++)
                    {
                        graphPanelMTF.X[i] = ((float)i / (padded.Length / 2)) * (samplingFrequency / 2);
                    }

                    graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, (float)(samplingFrequency / 2), 1.0f);
                    graphPanelMTF.XUnits = "cycles / mm";
                }
            }
        }

        protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
        {
            string directory = System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData);

            if (System.IO.File.Exists(directory + "\\" + Resource.OptionsFileName))
            {
                System.IO.File.Delete(directory + "\\" + Resource.OptionsFileName);
            }

            using (System.IO.Stream stream = System.IO.File.OpenWrite(directory + "\\" + Resource.OptionsFileName))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(Options));

                serializer.Serialize(stream, options);
            }

            base.OnClosing(e);
        }

        protected override void OnResize(EventArgs e)
        {
            base.OnResize(e);

            graphPanelMTF.Invalidate();
        }

        private void aboutToolStripMenuItem_Click(object sender, EventArgs e)
        {
            aboutForm.ShowDialog();
        }

        private void copyToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (graphPanelMTF.X != null && graphPanelMTF.Y != null && graphPanelMTF.X.Length == graphPanelMTF.Y.Length)
            {
                string s = options.XLabel;

                if (graphPanelMTF.XUnits != string.Empty)
                {
                    s += " ( " + graphPanelMTF.XUnits + " )";
                }

                s += "\t" + options.YLabel;

                if (graphPanelMTF.YUnits != string.Empty)
                {
                    s += " ( " + graphPanelMTF.YUnits + " )";
                }

                s += "\n";

                for (int i = 0; i < graphPanelMTF.X.Length; i++)
                {
                    s += graphPanelMTF.X[i].ToString() + "\t" + graphPanelMTF.Y[i].ToString() + "\n";
                }

                Clipboard.SetData(DataFormats.StringFormat, s);
            }
            else
            {
                MessageBox.Show("An image must be loaded before the Modulation Transfer Function can be copied to the clipboard.", 
                    Resource.MessageBoxCaption);
            }
        }

        private void exitToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void openToolStripMenuItem_Click(object sender, EventArgs e)
        {
            OpenFileDialog dialog = new OpenFileDialog();

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                if (System.IO.Path.GetExtension(dialog.FileName).ToUpper() == ".DCM")
                {
                    // Convert the DICOM image to PNG.

                    Status = "Converting from DICOM to PNG ...";

                    using (System.Diagnostics.Process process = new System.Diagnostics.Process())
                    {
                        process.StartInfo.Arguments         = "\"" + dialog.FileName + "\"" + " -p";
                        process.StartInfo.FileName          = "dicom2.exe";
                        process.StartInfo.WindowStyle       = System.Diagnostics.ProcessWindowStyle.Hidden;
                        process.StartInfo.WorkingDirectory  = System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
                        
                        process.EnableRaisingEvents = false;
                        
                        process.Start();
                        process.WaitForExit();
                    }

                    // Read and store the DICOM header.

                    Status = "Reading the DICOM header information ...";

                    using (System.Diagnostics.Process process = new System.Diagnostics.Process())
                    {
                        process.StartInfo.Arguments                 = "\"" + dialog.FileName + "\"" + " -t1";
                        process.StartInfo.FileName                  = "dicom2.exe";
                        process.StartInfo.RedirectStandardOutput    = true;
                        process.StartInfo.UseShellExecute           = false;
                        process.StartInfo.WindowStyle               = System.Diagnostics.ProcessWindowStyle.Hidden;
                        process.StartInfo.WorkingDirectory          = System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);

                        process.EnableRaisingEvents = false;

                        process.Start();

                        textBox.Text = process.StandardOutput.ReadToEnd();

                        process.WaitForExit();
                    }

                    // Make sure the PNG file exists and point dialog.FileName at the new file.

                    string filename = System.IO.Path.GetDirectoryName(dialog.FileName) + "\\" + System.IO.Path.GetFileNameWithoutExtension(dialog.FileName) + ".DCM.PNG";

                    if (System.IO.File.Exists(filename))
                    {
                        dialog.FileName = filename;
                    }
                    else
                    {
                        Status = "Failed to convert " + System.IO.Path.GetFileName(dialog.FileName) + " from DICOM to PNG.";

                        return;
                    }
                }
                else
                {
                    textBox.Text = string.Empty;
                }


                Status = "Loading " + System.IO.Path.GetFileName(dialog.FileName) + " ...";

                try
                {
                    bitmap = (Bitmap)Bitmap.FromFile(dialog.FileName);
                }
                catch (Exception exception)
                {
                    MessageBox.Show("Failed to load " + System.IO.Path.GetFileName(dialog.FileName) + " for the following reason: " + exception.Message, Resource.MessageBoxCaption);
                }

                if (bitmap != null && bitmap.Height > options.AveragingWindowLength && bitmap.Width > 0)
                {
                    Text = "Modulation Transfer Function Calculator (" + System.IO.Path.GetFileName(dialog.FileName) + ")";

                    Compute(bitmap);
                }
                else
                {
                    MessageBox.Show("Cannot use " + System.IO.Path.GetFileName(dialog.FileName) + " because reading the image returned null or because the image was too small.", Resource.MessageBoxCaption);
                }
            }
        }

        private void Compute(Bitmap bitmap)
        {
            // Crop the image to the crop rectangle, using the image width and height if no other value is specified.

            Status = "Cropping ...";

            Rectangle cropRectangle = options.CropRectangle;

            if (cropRectangle.Width == 0 || cropRectangle.Width > bitmap.Width)
            {
                cropRectangle.Width = bitmap.Width;
            }

            if (cropRectangle.Height == 0 || cropRectangle.Height > bitmap.Height)
            {
                cropRectangle.Height = bitmap.Height;
            }

            imagePanel.Crop  = cropRectangle;
            imagePanel.Image = bitmap;

            Bitmap croppedBitmap = new Bitmap(cropRectangle.Width, cropRectangle.Height);

            using (Graphics g = Graphics.FromImage(croppedBitmap))
            {
                g.DrawImage(bitmap, new Rectangle(-cropRectangle.Left, -cropRectangle.Top, bitmap.Width, bitmap.Height),
                    new Rectangle(0, 0, bitmap.Width, bitmap.Height), GraphicsUnit.Pixel);
            }

            // Find the average pixel values across the top and bottom.

            Status = "Straightening ...";

            int topEdge    = 0;
            int bottomEdge = 0;

            double topAverage    = 0.0;
            double bottomAverage = 0.0;

            for (int i = 0; i < croppedBitmap.Width; i++)
            {
                for (int j = 0; j < options.AveragingWindowLength; j++)
                {
                    topAverage += croppedBitmap.GetPixel(i, j).GetBrightness();
                }
            }

            topAverage /= croppedBitmap.Width * options.AveragingWindowLength;

            for (int i = 0; i < croppedBitmap.Width; i++)
            {
                for (int j = croppedBitmap.Height - 1 - options.AveragingWindowLength; j < croppedBitmap.Height - 1; j++)
                {
                    bottomAverage += croppedBitmap.GetPixel(i, j).GetBrightness();
                }
            }

            bottomAverage /= croppedBitmap.Width * options.AveragingWindowLength;

            // Find the first place the running average crosses the average across the top of the image.

            double runningAverage  = 0.0;
            double previousAverage = 0.0;

            for (int j = 0; j < options.AveragingWindowLength; j++)
            {
                runningAverage += croppedBitmap.GetPixel(0, j).GetBrightness() / options.AveragingWindowLength;
            }

            for (int i = 1; i < croppedBitmap.Width; i++)
            {
                previousAverage = runningAverage;
                runningAverage  = 0.0;

                for (int j = 0; j < options.AveragingWindowLength; j++)
                {
                    runningAverage += croppedBitmap.GetPixel(i, j).GetBrightness() / options.AveragingWindowLength;
                }

                if ((previousAverage < topAverage && runningAverage >= topAverage) || 
                    (previousAverage > topAverage && runningAverage <= topAverage))
                {
                    topEdge = i; break;
                }
            }

            // Find the first place the running average crosses the average across the bottom of the image. 

            runningAverage  = 0.0;
            previousAverage = 0.0;

            for (int j = 0; j < options.AveragingWindowLength; j++)
            {
                runningAverage += croppedBitmap.GetPixel(0, croppedBitmap.Height - 1 - j).GetBrightness() / options.AveragingWindowLength;
            }

            for (int i = 1; i < croppedBitmap.Width; i++)
            {
                previousAverage = runningAverage;
                runningAverage  = 0.0;

                for (int j = 0; j < options.AveragingWindowLength; j++)
                {
                    runningAverage += croppedBitmap.GetPixel(i, croppedBitmap.Height - 1 - j).GetBrightness() / options.AveragingWindowLength;
                }

                if ((previousAverage < bottomAverage && runningAverage >= bottomAverage) || 
                    (previousAverage > bottomAverage && runningAverage <= bottomAverage))
                {
                    bottomEdge = i; break;
                }
            }

            // Calculate the required rotation angle.

            double angle = Math.Atan2(Math.Abs(bottomEdge - topEdge), croppedBitmap.Height - options.AveragingWindowLength) * 180 / Math.PI;

            if (Math.Abs(angle) > 15.0)
            {
                MessageBox.Show("A significant portion of the image may be lost because the required rotation angle is larger than 15 degrees.  Make sure you have the right image and the right crop rectangle.", Resource.MessageBoxCaption);
            }

            // Flip the image horizontally if the edge runs from right to left.

            if (bottomEdge < topEdge)
            {
                croppedBitmap.RotateFlip(RotateFlipType.Rotate180FlipX);
            }

            // Calculate the crop offsets based on the rotation angle.

            int w = (int)Math.Ceiling(croppedBitmap.Width  * Math.Tan(angle * Math.PI / 180));
            int h = (int)Math.Ceiling(croppedBitmap.Height * Math.Tan(angle * Math.PI / 180));

            // Rotate and translate the image as appropriate.

            if (croppedBitmap.Width - h <= 0 || croppedBitmap.Height - w <= 0)
            {
                MessageBox.Show("Not enough of the image was left after cropping and rotating to proceed.  Make sure you have the right image and the right crop rectangle.", Resource.MessageBoxCaption);

                return;
            }

            Bitmap straightenedBitmap = new Bitmap(croppedBitmap.Width - h, croppedBitmap.Height - w);

            using (Graphics g = Graphics.FromImage(straightenedBitmap))
            {
                Matrix m = new Matrix();

                m.Rotate((float)angle);

                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Transform     = m;

                g.DrawImage(croppedBitmap, new Rectangle(0, -w, croppedBitmap.Width, croppedBitmap.Height),
                    new Rectangle(0, 0, croppedBitmap.Width, croppedBitmap.Height), GraphicsUnit.Pixel);
            }

            graphPanelLSF.Panel.BackgroundImageLayout = ImageLayout.Stretch;
            graphPanelLSF.Panel.BackgroundImage       = straightenedBitmap;

            Status = "Calculating the Line Spread Function ...";

            double[] real = new double[straightenedBitmap.Width];

            for (int i = 0; i < straightenedBitmap.Width; i++)
            {
                real[i] = 0.0;

                for (int j = 0; j < straightenedBitmap.Height; j++)
                {
                    real[i] += (straightenedBitmap as Bitmap).GetPixel(i, j).GetBrightness() / straightenedBitmap.Height;
                }
            }

            // Calculate the Line Spread Function from the step response.

            double[] difference = new double[straightenedBitmap.Width];

            for (int i = 0; i < straightenedBitmap.Width - 1; i++)
            {
                difference[i] = real[i] - real[i + 1];
            }

            graphPanelLSF.X = new double[difference.Length];
            graphPanelLSF.Y = new double[difference.Length];

            for (int i = 0; i < difference.Length; i++)
            {
                graphPanelLSF.X[i] = (double)(i) * options.PixelSpacing;
                graphPanelLSF.Y[i] = difference[i];
            }

            graphPanelLSF.Color  = Color.Red;
            graphPanelLSF.Limits = new RectangleF(0.0f, -1.0f, (float)(difference.Length) * (float)(options.PixelSpacing), 2.0f);

            // Window the LSF.

            Status = "Calculating the Modulation Transfer Function ...";

            MTF.HannWindow(difference);

            // Pad the windowed Line Spread Function with zeros until its length is equal to a power of 2.

            double[] padded = MTF.ZeroPad(difference);

            // Calculate the Modulation Transfer Function.

            MTF.Compute(padded);

            graphPanelMTF.Y = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                graphPanelMTF.Y[i] = padded[i];
            }

            Smooth(graphPanelMTF.Y, options.SmoothingKernelLength);

            Normalize(graphPanelMTF.Y);

            double samplingFrequency = 1 / options.PixelSpacing;

            graphPanelMTF.X = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                graphPanelMTF.X[i] = ((float)i / (padded.Length / 2)) * (samplingFrequency / 2);
            }

            graphPanelMTF.Color           = Color.Black;
            graphPanelMTF.Limits          = new RectangleF(0.0f, -0.1f, (float)(samplingFrequency / 2), 1.2f);
            graphPanelMTF.TenPercentLine  = true;
            graphPanelMTF.XUnits          = options.XUnits;
            graphPanelMTF.YUnits          = options.YUnits;

            graphPanelLSF.Invalidate();
            graphPanelMTF.Invalidate();

            Status = "Calculation succeeded.";
        }

        /// <summary>
        /// Normalizes a function so that its maximum value is unity.
        /// </summary>
        /// <param name="x"></param>
        private void Normalize(double[] x)
        {
            double maximum = 0.0;

            for (int i = 0; i < x.Length; i++)
            {
                if (x[i] > maximum) maximum = x[i];
            }

            for (int i = 0; i < x.Length; i++)
            {
                x[i] = x[i] / maximum;
            }
        }

        /// <summary>
        /// Smooth the input using a simple averaging window.
        /// </summary>
        /// <param name="x">Function to be smoothed.</param>
        /// <param name="n">Smoothing kernel length.</param>
        private void Smooth(double[] x, int n)
        {
            if (n > 0)
            {
                double[] y = new double[x.Length];

                for (int i = 0; i < x.Length; i++)
                {
                    y[i] = 0.0;
                }

                for (int i = 0; i < x.Length; i++)
                {
                    for (int j = 0; j < n; j++)
                    {
                        int k = Math.Min(x.Length - 1, Math.Max(0, i - (j - n / 2)));

                        y[i] = y[i] + x[k] / n;
                    }
                }

                for (int i = 0; i < x.Length; i++)
                {
                    x[i] = y[i];
                }
            }
        }

        private void optionsToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Options previousOptions = options.Clone() as Options;

            optionsForm.ShowDialog();

            graphPanelMTF.XUnits = options.XUnits;
            graphPanelMTF.YUnits = options.YUnits;

            if (previousOptions.PixelSpacing != options.PixelSpacing)
            {
                if (graphPanelMTF.X != null)
                {
                    double samplingFrequency = 1 / options.PixelSpacing;

                    for (int i = 0; i < graphPanelMTF.X.Length; i++)
                    {
                        graphPanelMTF.X[i] = ((float)i / graphPanelMTF.X.Length) * (samplingFrequency / 2);
                    }

                    graphPanelMTF.Limits = new RectangleF(0.0f, -0.1f, (float)(samplingFrequency / 2), 1.2f);
                }
            }

            if (previousOptions.AveragingWindowLength != options.AveragingWindowLength ||
                previousOptions.CropRectangle         != options.CropRectangle ||
                previousOptions.SmoothingKernelLength != options.SmoothingKernelLength)
            {
                if (bitmap != null)
                {
                    Compute(bitmap);
                }
            }

            imagePanel.Invalidate();

            graphPanelLSF.Invalidate();
            graphPanelMTF.Invalidate();
        }

        private void saveToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (filename != string.Empty)
            {
                Save();
            }
            else
            {
                saveAsToolStripMenuItem_Click(this, EventArgs.Empty);
            }
        }

        private void saveAsToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (graphPanelMTF.X != null && graphPanelMTF.Y != null)
            {
                SaveFileDialog dialog = new SaveFileDialog();

                dialog.Filter = "Comma-Separated Values (*.csv)|*.csv";

                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    filename = dialog.FileName;

                    Save();
                }
            }
            else
            {
                MessageBox.Show("An image must be loaded before saving the Modulation Transfer Function.", 
                    Resource.MessageBoxCaption);
            }
        }
    }
}
