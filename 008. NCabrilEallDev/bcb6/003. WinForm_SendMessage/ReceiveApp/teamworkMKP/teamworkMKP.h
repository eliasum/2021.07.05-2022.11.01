//---------------------------------------------------------------------------

#ifndef teamworkMKPH
#define teamworkMKPH
#define WM_SEND_TO_IMAGEPROG WM_USER+20
#define WM_SET_CAM_SETTINGS_IMAGEPROG WM_USER+21
#define INISETTINGFILENAME "MKPSettings.ini"

#include <IniFiles.hpp>
//---------------------------------------------------------------------------
//структура данных МКП для передачи программе, работающей с изображением
    enum
    {
        EN_EYE_GAIN,//Усиление
        EN_EYE_EXPO,//Экспозиция
        EN_DATA_MKP,//структура данных режима
    };
struct SDataMKPTransfer
{
	int num_poz;
	AnsiString sNumMKP;//номер МКП
	double dUscr;//напряжение экрана
	double dUmkp;//напряжение мкп
	double dUretard;//нтормозящее
	double dUacceler;//ускоряющее
	double dUanod;//анод
	double dUmod;//модулятор
	double dItk;//термокатод (мА)
	double dIout;//выходной ток(экрана в нм)
	double dPxel;
	int iTypeMkp;
    SDataMKPTransfer()
    {
		num_poz=0;
        sNumMKP="111";
		dUscr = 2.;
        dUmkp = 3.;
        dUretard = 4.;
        dUacceler = 5.;
        dUanod = 6.;
        dUmod = 7.;
		dItk = 8.;
		dIout = 9.;
		dPxel = 0.042;
		iTypeMkp = 1;
		//1 - 18mm
		//else 24mm
	}
	SDataMKPTransfer(SDataMKPTransfer& data)
    {
        num_poz=data.num_poz;
		sNumMKP=data.sNumMKP;
		dUscr = data.dUscr;
		dUmkp = data.dUmkp;
		dUretard = data.dUretard;
		dUacceler = data.dUacceler;
		dUanod = data.dUanod;
		dUmod = data.dUmod;
		dItk = data.dItk;
		dIout = data.dIout;
		dPxel = data.dPxel;
		iTypeMkp = data.iTypeMkp;
	}

};

void* GetImgProcesHandel()
{
	return FindWindow(NULL, "UeyeWindow");
}

void ReadSnapInfoFromFile(AnsiString FilePath, SDataMKPTransfer* SData)
{
	if(!SData) return;
	TIniFile* ini = new TIniFile(FilePath);
		SData->num_poz = ini->ReadInteger("SnapSettings","num_poz", 0);
		SData->sNumMKP = ini->ReadString("SnapSettings","sNumMKP", "");
		SData->dUscr = ini->ReadFloat("SnapSettings","dUscr", 0);
		SData->dUmkp = ini->ReadFloat("SnapSettings","dUmkp", 0);
		SData->dUretard = ini->ReadFloat("SnapSettings","dUretard", 0);
		SData->dUacceler = ini->ReadFloat("SnapSettings","dUacceler", 0);
		SData->dUanod = ini->ReadFloat("SnapSettings","dUanod", 0);
		SData->dUmod = ini->ReadFloat("SnapSettings","dUmod", 0);
		SData->dItk = ini->ReadFloat("SnapSettings","dItk", 0);
		SData->dIout = ini->ReadFloat("SnapSettings","dIout", 0);
		SData->dPxel = ini->ReadFloat("SnapSettings","dPxel", 0.042);
		//0.042
		//0.053 24

		SData->iTypeMkp = ini->ReadInteger("SnapSettings","iTypeMkp", 0.012);
	delete ini;

}

void WriteSnapInfoFromFile(AnsiString FilePath, SDataMKPTransfer* SData)
{
	if(!SData) return;
	TIniFile* ini = new TIniFile(FilePath);
 		ini->WriteInteger("SnapSettings","num_poz", SData->num_poz);
		ini->WriteString("SnapSettings","sNumMKP", SData->sNumMKP);
		ini->WriteFloat("SnapSettings","dUscr", SData->dUscr);
		ini->WriteFloat("SnapSettings","dUmkp", SData->dUmkp);
		ini->WriteFloat("SnapSettings","dUretard", SData->dUretard);
		ini->WriteFloat("SnapSettings","dUacceler", SData->dUacceler);
		ini->WriteFloat("SnapSettings","dUanod", SData->dUanod);
		ini->WriteFloat("SnapSettings","dUmod", SData->dUmod);
		ini->WriteFloat("SnapSettings","dItk", SData->dItk);
		ini->WriteFloat("SnapSettings","dIout", SData->dIout);
		ini->WriteFloat("SnapSettings","dPxel", SData->dPxel);
		ini->WriteInteger("SnapSettings","iTypeMkp", SData->iTypeMkp);
	delete ini;
}



#endif
