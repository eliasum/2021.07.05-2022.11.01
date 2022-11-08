using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace MTFCalculator
{
    public class GraphPanel : Panel
    {
        private bool tenPercentLine = false;

        public bool TenPercentLine
        {
            get 
            { 
                return tenPercentLine; 
            }
            set 
            { 
                tenPercentLine = value; 
            }
        }

        private Color color = Color.Black;

        public Color Color
        {
            get 
            { 
                return color; 
            }
            set 
            { 
                color = value; 
            }
        }

        private Point mouseLocation;

        private DoubleBufferedPanel panel = new DoubleBufferedPanel();

        public DoubleBufferedPanel Panel
        {
            get 
            { 
                return panel;
            }
            set 
            { 
                panel = value; 
            }
        }

        private double[] x = null;

        public double[] X
        {
            get 
            { 
                return x; 
            }
            set 
            { 
                x = value;
            }
        }

        private double[] y = null;

        public double[] Y
        {
            get 
            { 
                return y; 
            }
            set 
            { 
                y = value;
            }
        }

        private RectangleF limits = new RectangleF();

        public RectangleF Limits
        {
            get 
            { 
                return limits; 
            }
            set 
            { 
                limits = value; 
            }
        }

        private string xUnits = string.Empty;

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

        public GraphPanel()
        {
            Padding = new Padding(10);

            panel.BorderStyle   = BorderStyle.FixedSingle;
            panel.BackColor     = Color.White;
            panel.Cursor        = Cursors.Cross;
            panel.Dock          = DockStyle.Fill;

            Controls.Add(panel);

            panel.MouseMove += new MouseEventHandler(panel_MouseMove);
            panel.Paint     += new PaintEventHandler(panel_Paint);
        }

        /// <summary>
        /// Finds the first value below 0.10 in a monotonically decreasing function.
        /// </summary>
        /// <param name="x">Values of the function parameter x.</param>
        /// <param name="y">Values of the function evaluated at each value of the function parameter x.</param>
        /// <returns></returns>
        private double LocateTenPercentValue(double[] x, double[] y)
        {
            for (int i = 1; i < x.Length; i++)
            {
                if (y[i] < 0.10)
                {
                    if (y[i] - y[i - 1] == 0.0)
                    {
                        // Avoid a divide by zero error.

                        return 0.0;
                    }
                    else
                    {
                        // Return the value along the x axis that corrosponds to a y value of 0.10.

                        return x[i - 1] + (0.10 - y[i - 1]) * (x[i] - x[i - 1]) / (y[i] - y[i - 1]);
                    }
                }
            }

            return 0.0;
        }

        void panel_Paint(object sender, PaintEventArgs e)
        {
            e.Graphics.SmoothingMode     = SmoothingMode.AntiAlias;
            e.Graphics.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

            if (x != null && y != null)
            {
                GraphicsPath path = new GraphicsPath();

                float h = (float)(panel.Size.Height);
                float w = (float)(panel.Size.Width) + (float)(panel.Size.Width)  / (float)(y.Length);

                for (int i = 0; i < y.Length - 1; i++)
                {
                    float xa = (float)((x[i    ] - limits.Left) * (w / limits.Width));
                    float xb = (float)((x[i + 1] - limits.Left) * (w / limits.Width));

                    float ya = (float)(h - (y[i    ] - limits.Top) * (h / limits.Height));
                    float yb = (float)(h - (y[i + 1] - limits.Top) * (h / limits.Height));

                    path.AddLine(xa, ya, xb, yb);
                }

                e.Graphics.DrawPath(new Pen(color, 2.0f), path);

                float mx = (float)((mouseLocation.X / w) * limits.Width + limits.Left);
                float my = (float)(((h - mouseLocation.Y) / h) * limits.Height + limits.Top);

                StringFormat format = new StringFormat();

                format.Alignment     = StringAlignment.Far;
                format.LineAlignment = StringAlignment.Near;

                string xString = mx.ToString("f2");
                string yString = my.ToString("f2");

                if (xUnits != string.Empty)
                {
                    xString += " " + xUnits;
                }

                if (yUnits != string.Empty)
                {
                    yString += " " + yUnits;
                }

                e.Graphics.DrawString("( " + xString + ", " + yString + " )",
                    new Font("Helvetica", 12), Brushes.Red, new PointF(panel.Size.Width - 10, 10), format);

                if (tenPercentLine)
                {
                    double ten = LocateTenPercentValue(X, Y);

                    e.Graphics.DrawLine(new Pen(Color.Red, 1.0f),
                        new Point((int)((x[0] - limits.Left) * (w / limits.Width)), (int)(h - (0.10 - limits.Top) * (h / limits.Height))),
                        new Point((int)((x[x.Length - 1] - limits.Left) * (w / limits.Width)), (int)(h - (0.10 - limits.Top) * (h / limits.Height))));

                    if (ten > 0.0)
                    {
                        e.Graphics.DrawLine(new Pen(Color.Red, 1.0f),
                            new Point((int)((ten - limits.Left) * (w / limits.Width)), (int)(h - (0.15 - limits.Top) * (h / limits.Height))),
                            new Point((int)((ten - limits.Left) * (w / limits.Width)), (int)(h - (0.05 - limits.Top) * (h / limits.Height))));

                        format.Alignment = StringAlignment.Far;
                        format.LineAlignment = StringAlignment.Near;

                        e.Graphics.DrawString(ten.ToString("f4"), new Font("Helvetica", 12), Brushes.Red, new PointF(
                            (float)((ten - limits.Left) * (w / limits.Width)) - 10,
                            (float)(h - (0.10 - limits.Top) * (h / limits.Height)) + 10), format);
                    }
                }
            }
        }

        void panel_MouseMove(object sender, MouseEventArgs e)
        {
            mouseLocation = e.Location;

            panel.Invalidate();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            panel.Invalidate();
        }
    }
}
