package util

import (
	"go.uber.org/zap/zapcore"
)

func GetZapLogLevel(userLogLevel string) zapcore.Level {
	switch userLogLevel {
	case "debug":
		return zapcore.DebugLevel
	case "error":
		return zapcore.ErrorLevel
	case "info":
		return zapcore.InfoLevel
	default:
		return zapcore.InfoLevel
	}
}