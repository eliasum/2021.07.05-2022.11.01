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