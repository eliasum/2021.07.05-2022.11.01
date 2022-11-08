/*2021.10.26 17:14 IMM*/

/*
        Приложение SendApp имитирует приложение Cabril_III.exe и
        взаимодействует с приложением ReceiveApp, которое имитирует
        приложение uEYEcam.exe.

        С помощью функции FindWindow() ищется дескриптор окна
        экземпляра приложения с заголовком "UeyeWindow".
        Если такой экземпляр запущен, то передается сообщение с помощью
        функции EventSetGainExpo().
        Если же окно с заголовком "UeyeWindow" не открыто, тогда
        запускается приложение uEYEcam.exe в папке EXE и так же
        передается сообщение с помощью функции EventSetGainExpo()
*/
//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "MainUnit.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TFormMain *FormMain;
//---------------------------------------------------------------------------
__fastcall TFormMain::TFormMain(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TFormMain::sb1Click(TObject *Sender)
{
        HWND wnd = (HWND)GetImgProcesHandel();
        if(wnd==NULL)
        {
            AnsiString path = ExtractFilePath(Application->ExeName)+"EXE\\uEYEcam.exe";
            if(FileExists(path))
            {
                //EventSetGainExpo(NULL);
                spawnlp(P_NOWAIT, path.c_str(), path.c_str());
                EventSetGainExpo(NULL);
            }
            else ShowMessage("Doesn't exist "+path);
        }
        if(wnd)
        {
            EventSetGainExpo(NULL);
        }
}
//---------------------------------------------------------------------------
void __fastcall TFormMain::EventSetGainExpo(TObject* Object)
{
    /*
    AddMessage("Установка усиления иэкспозиции для камеры");
     TBaseProc* proc= GetFrame(0, 1);
    if(!proc)  {ShowMessage("!proc"); return;}
    if(IsUseEye)
    */
    {
        HWND wnd = GetImgProcesHandel();

        /*if(!wnd)
        {/*ShowMessage("!wnd");*/       /*
          SDataMKPTransfer* ght = (SDataMKPTransfer*)proc->VGetValue(EN_DATA_MKP, NULL);
          if(!ght)  {AddMessage("Не передан объект SDataMKPTransfer in func EventSetGainExpo"); return;}
          AnsiString path = ExtractFilePath(Application->ExeName)+"EXE\\"+INISETTINGFILENAME;
          WriteSnapInfoFromFile(path, ght);
          return;
        }
        int gain = proc->VGetValue(EN_EYE_GAIN, 0);
        long expo = proc->VGetValue(EN_EYE_EXPO, 100);
        */
        int gain = 10;
        long expo = 100;
        //AddMessage("Передача программе uEYEcam gain and expo");
        PostMessage(wnd, WM_SET_CAM_SETTINGS_IMAGEPROG, gain, expo);//
        /*
        SDataMKPTransfer* ght = (SDataMKPTransfer*)proc->VGetValue(EN_DATA_MKP, NULL);
        if(!ght)  {AddMessage("Не передан объект SDataMKPTransfer in func EventSetGainExpo"); return;}
        AnsiString path = ExtractFilePath(Application->ExeName)+"EXE\\"+INISETTINGFILENAME;
        WriteSnapInfoFromFile(path, ght);
        //Idglobal::Sleep(2000);
        AddMessage("Write struct SDataMKPTransfer in path");
        PostMessage(wnd, WM_SEND_TO_IMAGEPROG, 0, 0);
        */
    }
}
//---------------------------------------------------------------------------
