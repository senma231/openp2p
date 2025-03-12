package core

import (
	"bytes"
	"encoding/binary"
	"net"
	"time"
)

func UDPWrite(conn *net.UDPConn, dst net.Addr, mainType uint16, subType uint16, packet interface{}) (len int, err error) {
	msg, err := newMessage(mainType, subType, packet)
	if err != nil {
		return 0, err
	}
	if dst == nil {
		return conn.Write(msg)
	}
	return conn.WriteTo(msg, dst)
}

func UDPRead(conn *net.UDPConn, timeout time.Duration) (ra net.Addr, head *openP2PHeader, buff []byte, length int, err error) {
	if timeout > 0 {
		err = conn.SetReadDeadline(time.Now().Add(timeout))
		if err != nil {
			gLog.Println(LvERROR, "SetReadDeadline error")
			return nil, nil, nil, 0, err
		}
	}

	buff = make([]byte, 1024)
	length, ra, err = conn.ReadFrom(buff)
	if err != nil {
		// gLog.Println(LevelDEBUG, "ReadFrom error")
		return nil, nil, nil, 0, err
	}
	head = &openP2PHeader{}
	err = binary.Read(bytes.NewReader(buff[:openP2PHeaderSize]), binary.LittleEndian, head)
	if err != nil || head.DataLen > uint32(len(buff)-openP2PHeaderSize) {
		gLog.Println(LvERROR, "parse p2pheader error:", err)
		return nil, nil, nil, 0, err
	}
	return
}
