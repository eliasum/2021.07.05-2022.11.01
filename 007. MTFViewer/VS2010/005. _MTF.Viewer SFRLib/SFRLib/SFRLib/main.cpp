#include <stdio.h>
#include <opencv2/opencv.hpp>
extern "C"
{
  double __declspec(dllexport) Add (double a, double b)
  {
	// ������ �� �����
	cv::Mat img = cv::read("./imgs/B-W_09deg_3.jpg", cv::IMREAD_GRAYSCALE);

    return a + b;
  }
}