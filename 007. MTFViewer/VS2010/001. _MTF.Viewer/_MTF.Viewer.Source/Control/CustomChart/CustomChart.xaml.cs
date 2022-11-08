namespace _MTF.Viewer.Control
{
    using System;
    using System.Windows;
    using System.Windows.Media;
    using System.Windows.Controls;
    using System.Windows.Media.Imaging;
    using System.Collections.ObjectModel;

    using Core = _AVM.Library.Core;
    using Processing = _IMM.Library;

    public partial class CustomChart : UserControl
    {
        private static Random random = new Random();

        public CustomChart()
        {
            InitializeComponent();
            this.chart.DataContext = new ObservableCollection<Point>();
        }

        public Point[] Add(Core.Image._8bit.Pixel[,] pixel)
        {
            this.list.Add("0", pixel);
            Collection<Point> collection =
                 ((Collection<Point>)this.chart.DataContext);
            collection.Clear();
            Point[] point = Processing.Image.ESF.Compute(pixel);
            //foreach (Point item in point) collection.Add(item);

            /*this.Add(new Point[] {
                new Point(random.Next(0, 10), random.Next(0, 100)),
                new Point(random.Next(0, 10), random.Next(0, 100)),
                new Point(random.Next(0, 10), random.Next(0, 100)),
                new Point(random.Next(0, 10), random.Next(0, 100)),
                new Point(random.Next(0, 10), random.Next(0, 100)),
                new Point(random.Next(0, 10), random.Next(0, 100)),
                new Point(random.Next(0, 10), random.Next(0, 100)),
                new Point(random.Next(0, 10), random.Next(0, 100)),
                new Point(random.Next(0, 10), random.Next(0, 100)),
                new Point(random.Next(0, 10), random.Next(0, 100)),
                new Point(random.Next(0, 10), random.Next(0, 100)) });*/

            return null;
        }

        public void Add(Point[] point)
        {
           Collection<Point> collection =
                ((Collection<Point>)this.chart.DataContext);
            foreach (Point item in point) collection.Add(item);
        }

        public void Add(Point point)
        {
            ((Collection<Point>)this.chart.DataContext).Add(point);
        }

        public void Clear()
        {
            ((Collection<Point>)this.chart.DataContext).Clear();
        }
    }
}
