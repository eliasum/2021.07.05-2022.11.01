namespace _MTF.Viewer.Command.Custom
{
    using System.Windows.Input;

    public static class Chart
    {
        public static readonly RoutedUICommand Mtf = new RoutedUICommand(
            "Mtf", "Mtf", typeof(Chart), new InputGestureCollection()
                {
                    new KeyGesture(Key.F5, ModifierKeys.Alt)
                });
        public static readonly RoutedUICommand Lsf = new RoutedUICommand(
            "Lsf", "Lsf", typeof(Chart), new InputGestureCollection()
                {
                    new KeyGesture(Key.F6, ModifierKeys.Alt)
                });
        public static readonly RoutedUICommand Esf = new RoutedUICommand(
            "Esf", "Esf", typeof(Chart), new InputGestureCollection()
                {
                    new KeyGesture(Key.F7, ModifierKeys.Alt)
                });
    }
}