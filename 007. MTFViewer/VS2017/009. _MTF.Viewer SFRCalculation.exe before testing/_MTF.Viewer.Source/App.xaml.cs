using System;
using System.Collections.Generic;
using System.Configuration;

using System.Linq;
using System.Threading;
using System.Windows;

namespace _MTF.Viewer.Source
{
    /// <summary>
    /// Логика взаимодействия для App.xaml
    /// </summary>
    public partial class App : Application
    {
        //Запуск одной копии приложения
        System.Threading.Mutex mutex;

        private void Application_Startup(object sender, StartupEventArgs e)
        {
            bool createdNew;
            string mutName = "Приложение";
            mutex = new System.Threading.Mutex(true, mutName, out createdNew);
            if (!createdNew)
            {
                this.Shutdown();
            }
        }
    }
}
