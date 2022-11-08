namespace _MTF.Viewer.Source.Control.CustomChart
{
    using System.Windows;
    using System.Windows.Media;
    using System.ComponentModel;
    using System.Windows.Controls;
    using System.Windows.Media.Imaging;
    using System.Collections.ObjectModel;

    using Core = _AVM.Library.Core;

    public partial class CustomListView : UserControl
    {
        public class Item : INotifyPropertyChanged
        {
            private string title;
            public string Title { get { return this.title; } set { this.title = value; } }

            private bool select;
            public bool Select { get { return this.select; } set { this.select = value; } }

            private BitmapSource image;
            public BitmapSource Image { get { return this.image; } set { this.image = value; } }


            public event PropertyChangedEventHandler PropertyChanged;
            private void OnPropertyChanged(string propertyName)
            {
                if (PropertyChanged != null)
                    PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
            }
        }

        private static ObservableCollection<Item> collection =
            new ObservableCollection<Item>();

        public CustomListView()
        {
            InitializeComponent();
            this.DataContext = collection;
        }

        public void Add(string title, Core.Image._8bit.Pixel[,] pixel)
        {
            Collection<Item> collection = ((Collection<Item>)this.DataContext);
            collection.Add(new Item()
            {
                Title = title,
                Select = true,
                Image = Core.Image._8bit.Create(pixel)
            });
        }
    }
}
