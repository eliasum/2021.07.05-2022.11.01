#include <stdio.h>
#include <opencv2/opencv.hpp>
extern "C"
{
  double __declspec(dllexport) Add (double a, double b)
  {
	// ������ �� �����
	cv::Mat img = cv::imread("", cv::IMREAD_GRAYSCALE);

    return a + b;
  }
}