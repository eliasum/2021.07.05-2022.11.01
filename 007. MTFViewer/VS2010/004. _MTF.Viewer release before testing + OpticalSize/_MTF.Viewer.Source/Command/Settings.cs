namespace _MTF.Viewer.Command.Custom
{
    using System.Windows.Input;

    public static class Settings
    {
        public static readonly RoutedUICommand Options = new RoutedUICommand(
            "Options", "Options", typeof(Settings), new InputGestureCollection()
                {
                    new KeyGesture(Key.F1, ModifierKeys.Alt),
                    new KeyGesture(Key.O, ModifierKeys.Control)
                });
    }
}