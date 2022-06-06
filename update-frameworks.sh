#!/bin/bash -e

carthage update ReactiveSwift --use-xcframeworks --platform ios,tvos,macCatalyst --configuration release
carthage update Quick Nimble --use-xcframeworks --platform ios --configuration release
