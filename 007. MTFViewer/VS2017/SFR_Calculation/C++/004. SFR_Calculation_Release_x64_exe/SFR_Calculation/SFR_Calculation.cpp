#include <iostream>
#include <opencv2/opencv.hpp>
/*---------------------------------------------------------------------*/
#include "sfr.h"

int main(int argc, char *argv[]) {

	//cv::Mat img = cv::imread("./imgs/original_img.bmp", cv::IMREAD_GRAYSCALE);
	cv::Mat img = cv::imread("./imgs/B-W_08deg_3.jpg", cv::IMREAD_GRAYSCALE);
	cv::Mat roi = img;

	if (roi.empty())
	{
		std::cerr << "No roi has been cropped" << std::endl;

		system("pause");

		return -1;
	}

	//	cv::imshow("roi", roi);
	//	cv::waitKey(0);
		cv::destroyAllWindows();

	std::cout << SFRCalculation(roi, 1) << std::endl;
	//system("pause");

	//return 0;
}