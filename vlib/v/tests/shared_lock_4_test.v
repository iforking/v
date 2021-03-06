import time

struct St {
mut:
	a int
}

fn (shared x St) f(shared z St) {
	for _ in 0 .. reads_per_thread {
		rlock x { // other instances may read at the same time
			time.sleep_ms(1)
			assert x.a == 7 || x.a == 5
		}
	}
	lock z {
		z.a--
	}
}

const (
	reads_per_thread = 30
	read_threads     = 10
	writes           = 5
)

fn test_shared_lock() {
	// object with separate read/write lock
	shared x := &St{
		a: 5
	}
	shared z := &St{
		a: read_threads
	}
	for _ in 0 .. read_threads {
		go x.f(shared z)
	}
	for i in 0 .. writes {
		lock x { // wait for ongoing reads to finish, don't start new ones
			x.a = 17 // this value should never be read
			time.sleep_ms(50)
			x.a = if (i & 1) == 0 { 7 } else { 5 }
		} // now new reads are possible again
		time.sleep_ms(20)
	}
	// wait until all read threads are finished
	for finished := false; true; {
		mut rr := 0
		rlock z {
			rr = z.a
			finished = z.a == 0
		}
		if finished {
			break
		}
		time.sleep_ms(100)
	}
}
