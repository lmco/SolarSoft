{ split($0,comps,"(")
 split(comps[2],addr,")")
 print addr[1]
}
