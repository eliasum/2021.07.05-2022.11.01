#include "sfr.h"
#include "pch.h"

void de_Gamma(cv::Mat &Src, double gamma)
{
	if (Src.channels() != 1) { return; }

	for (int i = 0; i < Src.rows; ++i)
	{
		uchar *SrcP = Src.ptr(i);
		for (int j = 0; j < Src.cols; ++j)
		{
			SrcP[j] = 255 * (pow((double)SrcP[j] / 255, 1 / gamma));
		}
	}
}