//---------------------------------------------------------------------------

#ifndef FormUnit1H
#define FormUnit1H
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <OleCtrls.hpp>

#include "teamworkMKP\teamworkMKP.h"
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TEdit *Edit1;
        TEdit *Edit2;
        TLabel *Label1;
        TLabel *Label2;
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
        
	void __fastcall exec_WM_SET_CAM_SETTINGS_IMAGEPROG(TMessage& msg);

	BEGIN_MESSAGE_MAP
		VCL_MESSAGE_HANDLER(WM_SET_CAM_SETTINGS_IMAGEPROG, TMessage, exec_WM_SET_CAM_SETTINGS_IMAGEPROG)
	END_MESSAGE_MAP(TForm)
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
