local logic = {}

function logic.do_timer(cb_id)
    print("[Lua] Initiating C++ async timer (500ms)...")
    cpp_async_sleep(500, function()
        print("[Lua] C++ timer fired! Informing Python...")
        cpp_call_py(cb_id)
    end)
end

return logic