namespace _MTF.Viewer.Command.Custom
{
    using System.Windows.Input;

    public static class File
    {
        public static readonly RoutedUICommand Open = new RoutedUICommand(
            "Open", "Open", typeof(File), new InputGestureCollection()
                {
                    new KeyGesture(Key.F1, ModifierKeys.Alt),
                    new KeyGesture(Key.O, ModifierKeys.Control)
                });
        public static readonly RoutedUICommand Save = new RoutedUICommand(
            "Save", "Save", typeof(File), new InputGestureCollection()
                {
                    new KeyGesture(Key.F2, ModifierKeys.Alt),
                    new KeyGesture(Key.S, ModifierKeys.Control)
                });
        public static readonly RoutedUICommand Exit = new RoutedUICommand(
            "Exit", "Exit", typeof(File), new InputGestureCollection()
                {
                    new KeyGesture(Key.F4, ModifierKeys.Alt),
                    new KeyGesture(Key.X, ModifierKeys.Control)
                });
    }
}