﻿#pragma checksum "..\..\DefectCheckControl.xaml" "{ff1816ec-aa5e-4d10-87f7-6f4963833460}" "70E66A2D4EF0D54EB36F5650E8E5F944FBC6F221"
//------------------------------------------------------------------------------
// <auto-generated>
//     Этот код создан программой.
//     Исполняемая версия:4.0.30319.42000
//
//     Изменения в этом файле могут привести к неправильной работе и будут потеряны в случае
//     повторной генерации кода.
// </auto-generated>
//------------------------------------------------------------------------------

using DefectCheckControlLibrary;
using System;
using System.Diagnostics;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Ink;
using System.Windows.Input;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Effects;
using System.Windows.Media.Imaging;
using System.Windows.Media.Media3D;
using System.Windows.Media.TextFormatting;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Windows.Shell;
using Xceed.Wpf.Toolkit;


namespace DefectCheckControlLibrary {
    
    
    /// <summary>
    /// DefectCheckControl
    /// </summary>
    public partial class DefectCheckControl : System.Windows.Controls.UserControl, System.Windows.Markup.IComponentConnector {
        
        private bool _contentLoaded;
        
        /// <summary>
        /// InitializeComponent
        /// </summary>
        [System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [System.CodeDom.Compiler.GeneratedCodeAttribute("PresentationBuildTasks", "4.0.0.0")]
        public void InitializeComponent() {
            if (_contentLoaded) {
                return;
            }
            _contentLoaded = true;
            System.Uri resourceLocater = new System.Uri("/DefectCheckControlLibrary;component/defectcheckcontrol.xaml", System.UriKind.Relative);
            
            #line 1 "..\..\DefectCheckControl.xaml"
            System.Windows.Application.LoadComponent(this, resourceLocater);
            
            #line default
            #line hidden
        }
        
        [System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [System.CodeDom.Compiler.GeneratedCodeAttribute("PresentationBuildTasks", "4.0.0.0")]
        [System.ComponentModel.EditorBrowsableAttribute(System.ComponentModel.EditorBrowsableState.Never)]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Design", "CA1033:InterfaceMethodsShouldBeCallableByChildTypes")]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Maintainability", "CA1502:AvoidExcessiveComplexity")]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1800:DoNotCastUnnecessarily")]
        void System.Windows.Markup.IComponentConnector.Connect(int connectionId, object target) {
            switch (connectionId)
            {
            case 1:
            
            #line 41 "..\..\DefectCheckControl.xaml"
            ((System.Windows.Controls.TextBlock)(target)).DataContextChanged += new System.Windows.DependencyPropertyChangedEventHandler(this.header_DataContextChanged);
            
            #line default
            #line hidden
            return;
            case 2:
            
            #line 53 "..\..\DefectCheckControl.xaml"
            ((System.Windows.Controls.TextBlock)(target)).DataContextChanged += new System.Windows.DependencyPropertyChangedEventHandler(this.header_DataContextChanged);
            
            #line default
            #line hidden
            return;
            case 3:
            
            #line 98 "..\..\DefectCheckControl.xaml"
            ((System.Windows.Controls.TextBlock)(target)).DataContextChanged += new System.Windows.DependencyPropertyChangedEventHandler(this.header_DataContextChanged);
            
            #line default
            #line hidden
            return;
            }
            this._contentLoaded = true;
        }
    }
}
