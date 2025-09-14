cmake_minimum_required(VERSION 3.10)
project(pdfium_dart LANGUAGES C)

# Compila a lib do wrapper + PDFium
add_subdirectory(../src build)
