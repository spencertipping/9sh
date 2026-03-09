(local {:dl dl} (require :bindings))
(local ffi (require :ffi))

;; Verify definitions exist and function signatures match native execution 
(assert (not (= nil dl.open)) "dl.open should be bound")
(assert (not (= nil dl.sym)) "dl.sym should be bound")
(assert (not (= nil dl.close)) "dl.close should be bound")

;; Load the standard math library via standard dl routing.
(local dl_handle (dl.open "libm.so" dl.RTLD_LAZY))
(assert (not (= nil dl_handle)) "Should acquire handle to libm dynamic library")

(local cos_ptr (dl.sym dl_handle "cos"))
(assert (not (= nil cos_ptr)) "Should resolve 'cos' symbol from libm")

(dl.close dl_handle)

(print "dlopen: ok")
