package core

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"log"
	"net"
	"strings"
	"sync"

	"github.com/emirpasic/gods/trees/avltree"
	"github.com/emirpasic/gods/utils"
)

type IPTree struct {
	tree    *avltree.Tree
	treeMtx sync.RWMutex
}
type IPTreeValue struct {
	maxIP uint32
	v     interface{}
}

// TODO: deal interset
func (iptree *IPTree) DelIntIP(minIP uint32, maxIP uint32) {
	iptree.tree.Remove(minIP)
}

// add 120k cost 0.5s
func (iptree *IPTree) AddIntIP(minIP uint32, maxIP uint32, v interface{}) bool {
	if minIP > maxIP {
		return false
	}
	iptree.treeMtx.Lock()
	defer iptree.treeMtx.Unlock()
	newMinIP := minIP
	newMaxIP := maxIP
	cur := iptree.tree.Root
	for {
		if cur == nil {
			break
		}
		tv := cur.Value.(*IPTreeValue)
		curMinIP := cur.Key.(uint32)

		// newNode all in existNode, treat as inserted.
		if newMinIP >= curMinIP && newMaxIP <= tv.maxIP {
			return true
		}
		// has no interset
		if newMinIP > tv.maxIP {
			cur = cur.Children[1]
			continue
		}
		if newMaxIP < curMinIP {
			cur = cur.Children[0]
			continue
		}
		// has interset, rm it and Add the new merged ip segment
		iptree.tree.Remove(curMinIP)
		if curMinIP < newMinIP {
			newMinIP = curMinIP
		}
		if tv.maxIP > newMaxIP {
			newMaxIP = tv.maxIP
		}
		cur = iptree.tree.Root
	}
	//  put in the tree
	iptree.tree.Put(newMinIP, &IPTreeValue{newMaxIP, v})
	return true
}

func (iptree *IPTree) Add(minIPStr string, maxIPStr string, v interface{}) bool {
	var minIP, maxIP uint32
	binary.Read(bytes.NewBuffer(net.ParseIP(minIPStr).To4()), binary.BigEndian, &minIP)
	binary.Read(bytes.NewBuffer(net.ParseIP(maxIPStr).To4()), binary.BigEndian, &maxIP)
	return iptree.AddIntIP(minIP, maxIP, v)
}

func (iptree *IPTree) Del(minIPStr string, maxIPStr string) {
	var minIP, maxIP uint32
	binary.Read(bytes.NewBuffer(net.ParseIP(minIPStr).To4()), binary.BigEndian, &minIP)
	binary.Read(bytes.NewBuffer(net.ParseIP(maxIPStr).To4()), binary.BigEndian, &maxIP)
	iptree.DelIntIP(minIP, maxIP)
}

func (iptree *IPTree) Contains(ipStr string) bool {
	var ip uint32
	binary.Read(bytes.NewBuffer(net.ParseIP(ipStr).To4()), binary.BigEndian, &ip)
	_, ok := iptree.Load(ip)
	return ok
}

func IsLocalhost(ipStr string) bool {
	if ipStr == "localhost" || ipStr == "127.0.0.1" || ipStr == "::1" {
		return true
	}
	return false
}

func (iptree *IPTree) Load(ip uint32) (interface{}, bool) {
	iptree.treeMtx.RLock()
	defer iptree.treeMtx.RUnlock()
	if iptree.tree == nil {
		return nil, false
	}
	n := iptree.tree.Root
	for n != nil {
		tv := n.Value.(*IPTreeValue)
		curMinIP := n.Key.(uint32)
		switch {
		case ip >= curMinIP && ip <= tv.maxIP: // hit
			return tv.v, true
		case ip < curMinIP:
			n = n.Children[0]
		default:
			n = n.Children[1]
		}
	}
	return nil, false
}

func (iptree *IPTree) Size() int {
	iptree.treeMtx.RLock()
	defer iptree.treeMtx.RUnlock()
	return iptree.tree.Size()
}

func (iptree *IPTree) Print() {
	iptree.treeMtx.RLock()
	defer iptree.treeMtx.RUnlock()
	log.Println("size:", iptree.Size())
	log.Println(iptree.tree.String())
}

func (iptree *IPTree) Clear() {
	iptree.treeMtx.Lock()
	defer iptree.treeMtx.Unlock()
	iptree.tree.Clear()
}

// input format 127.0.0.1,192.168.1.0/24,10.1.1.30-10.1.1.50
// 127.0.0.1
// 192.168.1.0/24
// 192.168.1.1-192.168.1.10
func NewIPTree(ips string) *IPTree {
	iptree := &IPTree{
		tree: avltree.NewWith(utils.UInt32Comparator),
	}
	ipArr := strings.Split(ips, ",")
	for _, ip := range ipArr {
		if strings.Contains(ip, "/") { // x.x.x.x/24
			_, ipNet, err := net.ParseCIDR(ip)
			if err != nil {
				fmt.Println("Error parsing CIDR:", err)
				continue
			}
			minIP := ipNet.IP.Mask(ipNet.Mask).String()
			maxIP := calculateMaxIP(ipNet).String()
			iptree.Add(minIP, maxIP, nil)
		} else if strings.Contains(ip, "-") { // x.x.x.x-y.y.y.y
			minAndMax := strings.Split(ip, "-")
			iptree.Add(minAndMax[0], minAndMax[1], nil)
		} else { // single ip
			iptree.Add(ip, ip, nil)
		}
	}
	return iptree
}
func calculateMaxIP(ipNet *net.IPNet) net.IP {
	maxIP := make(net.IP, len(ipNet.IP))
	copy(maxIP, ipNet.IP)
	for i := range maxIP {
		maxIP[i] |= ^ipNet.Mask[i]
	}
	return maxIP
}
