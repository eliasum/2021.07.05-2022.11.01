/*2021.10.26 17:14 IMM*/

/*
        ���������� SendApp ��������� ���������� Cabril_III.exe �
        ��������������� � ����������� ReceiveApp, ������� ���������
        ���������� uEYEcam.exe.

        � ������� ������� FindWindow() ������ ���������� ����
        ���������� ���������� � ���������� "UeyeWindow".
        ���� ����� ��������� �������, �� ���������� ��������� � �������
        ������� EventSetGainExpo().
        ���� �� ���� � ���������� "UeyeWindow" �� �������, �����
        ����������� ���������� uEYEcam.exe � ����� EXE � ��� ��
        ���������� ��������� � ������� ������� EventSetGainExpo()
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
        HWND wnd = GetImgProcesHandel();

        if(!wnd)
        ShowMessage("Cabril_III: ���� UeyeWindow �� �������!");

        int gain = 10;
        long expo = 100;

        PostMessage(wnd, WM_SET_CAM_SETTINGS_IMAGEPROG, gain, expo);
}
//---------------------------------------------------------------------------
