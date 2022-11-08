#include <iostream>
#include <opencv2/opencv.hpp>
/*---------------------------------------------------------------------*/
#include "sfr.h"

int main(int argc, char *argv[]) {

	cv::Mat img = cv::imread("./imgs/CroppedImage.jpg", cv::IMREAD_GRAYSCALE);
	cv::Mat roi = img;

	if (roi.empty())
	{
		std::cerr << "No roi has been cropped" << std::endl;

		system("pause");

		return -1;
	}

	cv::destroyAllWindows();

	std::cout << SFRCalculation(roi, 1) << std::endl;
}