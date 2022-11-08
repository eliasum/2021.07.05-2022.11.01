/*2021.10.28 18:02 IMM*/

/*
        Приложение ReceiveApp.
        
        Форма с заголовком 'UeyeWindow' - имитирует одноимённый
        заголовок приложения uEYEcam. После запуска этого приложения
        дескриптор экземпляра приложения можно найти по заголовку
        'UeyeWindow' с помощью функции FindWindow() WinAPI, что позволит
        работать с приложением ReceiveApp
*/

//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "FormUnit1.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TForm1 *Form1;
        int Gain = 0;
	int Exposure = 0;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TForm1::exec_WM_SET_CAM_SETTINGS_IMAGEPROG(TMessage& msg)
{
	Gain = msg.WParam;
	Exposure = msg.LParam;

        Edit1->Text = Gain;
        Edit2->Text = Exposure;

        ShowMessage("Обработано сообщение WM_SET_CAM_SETTINGS_IMAGEPROG");
}

//---------------------------------------------------------------------------

