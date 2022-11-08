﻿namespace _MTF.Viewer.Control
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

            /*
                нередко в качестве источника применяется класс ObservableCollection,
                который находится в пространстве имен System.Collections.ObjectModel.
                Его преимущество заключается в том, что при любом изменении
                ObservableCollection может уведомлять элементы, которые применяют 
                привязку, в результате чего обновляется не только сам объект 
                ObservableCollection, но и привязанные к нему элементы интерфейса.
            */
            this.chart.DataContext = new ObservableCollection<Point>();
        }

        /*
            1. добавление массива пикселей типа _AVM.Library.Core.Image._8bit.Pixel выбранной 
            прямоугольной области в список типа _MTF.Viewer.Source.Control.CustomChart.CustomListView,
            который позволяет вывести выбранные области внизу CustomChart, чтобы была возможность 
            выбрать прямоугольную область и рассчитать ESF для конкретной выбранной области
            2. Рассчёт Edge Spread Function
        */
        public Point[] AddPixels(Core.Image._8bit.Pixel[,] pixel)
        {
            /*
                добавить массив пикселей типа _AVM.Library.Core.Image._8bit.Pixel выбранной 
                прямоугольной области в список типа _MTF.Viewer.Source.Control.CustomChart.CustomListView,
                который позволяет вывести выбранные области внизу CustomChart, чтобы была возможность 
                выбрать прямоугольную область и рассчитать ESF для конкретной выбранной области
            */
            this.list.Add("0", pixel);

            /*
                --
            */
            
            Collection<Point> collection =
                 ((Collection<Point>)this.chart.DataContext);

            collection.Clear();
            
            // массив точек с рассчитанной Edge Spread Function
            Point[] point = Processing.Image.ESF.Compute(pixel);

            // вывод графиков
            foreach (Point item in point) collection.Add(item);

            return point;
        }

        public Point[] AddESFPoints(Point[] points)
        {
            if (points != null)
            {
                Collection<Point> collection =
                ((Collection<Point>)this.chart.DataContext);

                collection.Clear();

                // массив точек с рассчитанной Edge Spread Function
                Point[] point = Processing.Image.LSF.Compute(points);

                // вывод графиков
                foreach (Point item in point) collection.Add(item);

                return point;
            }
            return null; 
        }

        public Point[] Add(Point[] point)
        {
            Collection<Point> collection =
                 ((Collection<Point>)this.chart.DataContext);

            collection.Clear();

            return null; // TODO: убрать заглушку
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
