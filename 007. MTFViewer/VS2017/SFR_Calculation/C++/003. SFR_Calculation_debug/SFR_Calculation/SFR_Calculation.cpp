#include <iostream>
#include <opencv2/opencv.hpp>
/*---------------------------------------------------------------------*/
#include "sfr.h"

int main(int argc, char *argv[]) {

	//cv::Mat img = cv::imread("./imgs/original_img.bmp", cv::IMREAD_GRAYSCALE);

	// чтение из файла
	cv::Mat img = cv::imread("./imgs/B-W_07deg_3.jpg", cv::IMREAD_GRAYSCALE);

	// запись в файл
	//cv::imwrite("./imgs/WriteInput.jpg", img);

	cv::Mat roi = img;

	if (roi.empty())
	{
		std::cerr << "No roi has been cropped" << std::endl;
		return -1;
	}

/*
	cv::imshow("roi", roi);
	cv::waitKey(0);*/
	//cv::destroyAllWindows();

	// запись в файл
	//cv::imwrite("./imgs/WriteRoi.jpg", roi);

	std::cout << SFRCalculation(roi, 1) << std::endl;

	//system("pause");

	//return 0;
}