if not FocusModule then
    function FocusModule(handler) 
        -- default words for greeting and ungreeting the npc. Should be a table containing all such words.
        FOCUS_GREETWORDS = {"hi", "hello"}
        FOCUS_FAREWELLWORDS = {"bye", "farewell"}

        _module = {
            npcHandler = nil
        }

        -- Inits the module and associates handler to it.

        _module.npcHandler = handler
        for i, word in pairs(FOCUS_GREETWORDS) do
            local obj = {}
            obj[#obj + 1] = word
            obj.callback = FOCUS_GREETWORDS.callback or _module.messageMatcher
            handler.keywordHandler:addKeyword(obj, _module.onGreet, {module = _module})
        end

        for i, word in pairs(FOCUS_FAREWELLWORDS) do
            local obj = {}
            obj[#obj + 1] = word
            obj.callback = FOCUS_FAREWELLWORDS.callback or _module.messageMatcher
            handler.keywordHandler:addKeyword(obj, _module.onFarewell, {module = _module})
        end

        -- Greeting callback function.
        function _module.onGreet(cid, message, keywords, parameters)
            parameters.module.npcHandler:onGreet(cid)
            return true
        end

        -- UnGreeting callback function.
        function _module.onFarewell(cid, message, keywords, parameters)
            if parameters.module.npcHandler:isFocused(cid) then
                parameters.module.npcHandler:onFarewell(cid)
                return true
            else
                return false
            end
        end

        -- Custom message matching callback function for greeting messages.
        function _module.messageMatcher(keywords, message)
            for i, word in pairs(keywords) do
                if type(word) == "string" then
                    if string.find(message, word) and not string.find(message, "[%w+]" .. word) and not string.find(message, word .. "[%w+]") then
                        return true
                    end
                end
            end
            return false
        end

        return _module
    end
end