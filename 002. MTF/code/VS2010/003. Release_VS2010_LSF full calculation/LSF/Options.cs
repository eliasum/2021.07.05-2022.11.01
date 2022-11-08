using System;
using System.ComponentModel;
using System.Drawing;

namespace LSF
{
    [Serializable]

    public class Options : ICloneable
    {
        private int averagingWindowLength = 4;

        [Category("Image Processing")]
        [DisplayName("Averaging Window Length")]
        [Description("Number of rows to average when calculating the average pixel value along the top and bottom of the image.")]

        public int AveragingWindowLength
        {
            get 
            { 
                return averagingWindowLength; 
            }
            set 
            { 
                averagingWindowLength = value; 
            }
        }

        private Rectangle cropRectangle = new Rectangle(0, 0, 0, 0);

        [Category("Image Processing")]
        [DisplayName("Crop Rectangle")]
        [Description("A value of zero for the width or height will result in a width or height equal to that of the loaded image.")]

        public Rectangle CropRectangle
        {
            get 
            { 
                return cropRectangle; 
            }
            set 
            { 
                cropRectangle = value; 
            }
        }

        private double pixelSpacing = 0.1;

        [Category("Image Processing")]
        [DisplayName("Pixel Spacing")]

        public double PixelSpacing
        {
            get 
            { 
                return pixelSpacing; 
            }
            set 
            { 
                pixelSpacing = value; 
            }
        }

        private int smoothingKernelLength = 16;

        [Category("Image Processing")]
        [DisplayName("Smoothing Kernel Length")]
        [Description("Length of the averaging kernel used to smooth the calculated Modulation Transfer Function.")]

        public int SmoothingKernelLength
        {
            get 
            { 
                return smoothingKernelLength; 
            }
            set 
            { 
                smoothingKernelLength = value; 
            }
        }

        private string xLabel = "Spatial Frequency";

        [Category("Labels")]
        [DisplayName("X Label")]

        public string XLabel
        {
            get 
            { 
                return xLabel; 
            }
            set 
            { 
                xLabel = value; 
            }
        }

        private string yLabel = "Modulation Transfer Function";

        [Category("Labels")]
        [DisplayName("Y Label")]

        public string YLabel
        {
            get 
            { 
                return yLabel; 
            }
            set 
            { 
                yLabel = value; 
            }
        }

        private string xUnits = "cycles / mm";

        [Category("Units")]
        [DisplayName("X Units")]

        public string XUnits
        {
            get 
            { 
                return xUnits; 
            }
            set 
            { 
                xUnits = value; 
            }
        }

        private string yUnits = string.Empty;

        [Category("Units")]
        [DisplayName("Y Units")]

        public string YUnits
        {
            get 
            { 
                return yUnits; 
            }
            set 
            { 
                yUnits = value; 
            }
        }

        #region ICloneable Members

            public object Clone()
            {
                return this.MemberwiseClone();
            }

        #endregion
    }
}
