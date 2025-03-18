package core

import (
	"filepath"
	"fmt"
	"io"
	"log"
	"os"
	"runtime"
	"sync"
	"time"
)

type LogLevel int

var gLog *logger

const (
	LvDev   LogLevel = -1
	LvDEBUG LogLevel = iota
	LvINFO
	LvWARN
	LvERROR
)

var (
	logFileNames map[LogLevel]string
	loglevel     map[LogLevel]string
)

func init() {
	logFileNames = make(map[LogLevel]string)
	loglevel = make(map[LogLevel]string)
	logFileNames[0] = ".log"
	loglevel[LvDEBUG] = "DEBUG"
	loglevel[LvINFO] = "INFO"
	loglevel[LvWARN] = "WARN"
	loglevel[LvERROR] = "ERROR"
	loglevel[LvDev] = "Dev"

}

const (
	LogFile    = 1
	LogConsole = 1 << 1
)

type logger struct {
	loggers    map[LogLevel]*log.Logger
	files      map[LogLevel]*os.File
	level      LogLevel
	logDir     string
	mtx        *sync.Mutex
	lineEnding string
	pid        int
	maxLogSize int64
	mode       int
	stdLogger  *log.Logger
}

func NewLogger(path string, filePrefix string, level LogLevel, maxLogSize int64, mode int) *logger {
	loggers := make(map[LogLevel]*log.Logger)
	logfiles := make(map[LogLevel]*os.File)
	var (
		logdir string
	)
	if path == "" {
		logdir = "log/"
	} else {
		logdir = path + "/log/"
	}
	os.MkdirAll(logdir, 0777)
	for lv := range logFileNames {
		logFilePath := logdir + filePrefix + logFileNames[lv]
		f, err := os.OpenFile(logFilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
		if err != nil {
			log.Fatal(err)
		}
		os.Chmod(logFilePath, 0644)
		logfiles[lv] = f
		loggers[lv] = log.New(f, "", log.LstdFlags|log.Lmicroseconds)
	}
	var le string
	if runtime.GOOS == "windows" {
		le = "\r\n"
	} else {
		le = "\n"
	}
	pLog := &logger{loggers, logfiles, level, logdir, &sync.Mutex{}, le, os.Getpid(), maxLogSize, mode, log.New(os.Stdout, "", 0)}
	pLog.stdLogger.SetFlags(log.LstdFlags | log.Lmicroseconds)
	go pLog.checkFile()
	return pLog
}

func (l *logger) setLevel(level LogLevel) {
	l.mtx.Lock()
	defer l.mtx.Unlock()
	l.level = level
}

func (l *logger) setMaxSize(size int64) {
	l.mtx.Lock()
	defer l.mtx.Unlock()
	l.maxLogSize = size
}

func (l *logger) setMode(mode int) {
	l.mtx.Lock()
	defer l.mtx.Unlock()
	l.mode = mode
}

func (l *logger) checkFile() {
	if l.maxLogSize <= 0 {
		return
	}
	ticker := time.NewTicker(time.Minute)
	for {
		select {
		case <-ticker.C:
			l.mtx.Lock()
			for lv, logFile := range l.files {
				f, e := logFile.Stat()
				if e != nil {
					continue
				}
				if f.Size() <= l.maxLogSize {
					continue
				}
				logFile.Close()
				fname := f.Name()
				backupPath := l.logDir + fname + ".0"
				os.Remove(backupPath)
				os.Rename(l.logDir+fname, backupPath)
				newFile, e := os.OpenFile(l.logDir+fname, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
				if e == nil {
					l.loggers[lv].SetOutput(newFile)
					l.files[lv] = newFile
				}
			}
			l.mtx.Unlock()
		}
	}
}

func (l *logger) Printf(level LogLevel, format string, params ...interface{}) {
	l.mtx.Lock()
	defer l.mtx.Unlock()
	if level < l.level {
		return
	}
	pidAndLevel := []interface{}{l.pid, loglevel[level]}
	params = append(pidAndLevel, params...)
	if l.mode&LogFile != 0 {
		l.loggers[0].Printf("%d %s "+format+l.lineEnding, params...)
	}
	if l.mode&LogConsole != 0 {
		l.stdLogger.Printf("%d %s "+format+l.lineEnding, params...)
	}
}

func (l *logger) Println(level LogLevel, params ...interface{}) {
	l.mtx.Lock()
	defer l.mtx.Unlock()
	if level < l.level {
		return
	}
	pidAndLevel := []interface{}{l.pid, " ", loglevel[level], " "}
	params = append(pidAndLevel, params...)
	params = append(params, l.lineEnding)
	if l.mode&LogFile != 0 {
		l.loggers[0].Print(params...)
	}
	if l.mode&LogConsole != 0 {
		l.stdLogger.Print(params...)
	}
}

// 初始化日志
func InitLogger(logLevel int) {
	// 获取可执行文件所在目录
	execPath, err := os.Executable()
	if err != nil {
		fmt.Printf("获取可执行文件路径失败: %v\n", err)
		return
	}

	// 使用可执行文件所在目录作为日志目录
	logDir := filepath.Join(filepath.Dir(execPath), "logs")

	// 创建日志目录
	if err := os.MkdirAll(logDir, 0755); err != nil {
		fmt.Printf("创建日志目录失败: %v\n", err)
		return
	}

	// 生成日志文件名
	now := time.Now()
	logFileName := filepath.Join(logDir, fmt.Sprintf("client_%s.log", now.Format("20060102")))

	// 打开日志文件
	logFile, err := os.OpenFile(logFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		fmt.Printf("打开日志文件失败: %v\n", err)
		return
	}

	// 设置日志输出到文件和控制台
	log.SetOutput(io.MultiWriter(logFile, os.Stdout))

	// 设置日志格式
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)

	log.Printf("日志初始化完成，级别: %d, 路径: %s", logLevel, logFileName)
}
