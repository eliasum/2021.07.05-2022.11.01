using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace GridItemsControlLib
{
    /// <summary>
    /// Логика взаимодействия для GridItemsControl.xaml
    /// </summary>
    public partial class GridItemsControl : UserControl
    {
        public double[] sizes = new double[] { 1.0, 2.0, 3.0, 4.0 };
        public double[] Sizes
        {
            get { return sizes; }
        }

        public GridItemsControl()
        {
            InitializeComponent();

            this.DataContext = this;   
        }   
    }
}
