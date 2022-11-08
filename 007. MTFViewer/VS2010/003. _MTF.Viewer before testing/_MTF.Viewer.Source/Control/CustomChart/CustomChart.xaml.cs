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

        public Point[] AddPixels(Core.Image._8bit.Pixel[,] pixel)
        {
            this.list.Add("0", pixel);

            Collection<Point> collection =
                 ((Collection<Point>)this.chart.DataContext);

            collection.Clear();
            
            // массив точек с рассчитанной Edge Spread Function
            Point[] point = Processing.Image.ESF.Compute(pixel);

            if (point != null)
            {
                // добавление в коллекцию точек графиков ESF
                foreach (Point item in point) collection.Add(item);

                // точки графика ESF
                return point;
            }

            // очистить выбранные области внизу CustomChart
            this.list.DataContext = null;

            // удалить точки графиков ESF
            collection.Clear();

            return null;
        }

        public Point[] AddESFPoints(Point[] points)
        {
            if (points != null)
            {
                Collection<Point> collection =
                ((Collection<Point>)this.chart.DataContext);

                collection.Clear();

                // массив точек с рассчитанной Line Spread Function
                Point[] point = Processing.Image.LSF.Compute(points);

                foreach (Point item in point) collection.Add(item);

                return point;
            }
            return null; 
        }

        public Point[] AddLSFPoints(Point[] points)
        {
            if (points != null)
            {
                Collection<Point> collection =
                ((Collection<Point>)this.chart.DataContext);

                collection.Clear();

                // массив точек с рассчитанной Modulation Transfer Function
                Point[] point = Processing.Image.MTF.Compute(points);

                foreach (Point item in point) collection.Add(item);

                return point;
            }
            return null;
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
