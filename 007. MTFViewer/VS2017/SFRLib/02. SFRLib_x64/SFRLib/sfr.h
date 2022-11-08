#pragma once
#include <opencv2/opencv.hpp>
#include <vector>
#include <cstdlib>
#include <complex>
#include <cmath>
#include <iostream>
#include <fstream>
#include "pch.h"
#define M_PI 3.1415

#ifdef SFRLIBRARY_EXPORTS
#define SFRLIBRARY_API __declspec(dllexport)
#else
#define SFRLIBRARY_API __declspec(dllimport)
#endif

//extern "C" SFRLIBRARY_API void de_Gamma(cv::Mat &Src, double gamma);

extern "C" SFRLIBRARY_API int SFRCalculation(cv::Mat &ROI, double gamma);

extern "C" SFRLIBRARY_API void SLR(std::vector<double> &Cen_Shifts, std::vector<double> &y_shifts, double *a, double *b);

extern "C" SFRLIBRARY_API std::vector<double> CentroidFind(cv::Mat &Src, std::vector<double> &y_shifts, double *CCoffset);

extern "C" SFRLIBRARY_API std::vector<double> OverSampling(cv::Mat &Src, double slope, double CCoffset, int height, int width, int *SamplingLen);

extern "C" SFRLIBRARY_API std::vector<double> HammingWindows(std::vector<double> &deSampling, int SamplingLen);

extern "C" SFRLIBRARY_API void DFT(std::vector<double> &data, int size);