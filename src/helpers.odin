package main

import NS "core:sys/darwin/Foundation"

NS_String :: proc(str: string) -> ^NS.String {
	return NS.String.alloc()->initWithOdinString(str)
}
