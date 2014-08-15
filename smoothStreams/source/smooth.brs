'*************************************************************
'** login to smoothstreams and get id and password
'*************************************************************
Function login() as object
    'print "logging in"
    return showLoggingInDialog()
End Function

function showLoggingInDialog() as object
    screen = CreateObject("roOneLineDialog")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetTitle("Logging into " +RegRead("Service"))
    screen.ShowBusyAnimation()
    screen.show()
    searchRequest = CreateObject("roUrlTransfer")
    searchRequest.SetURL(getAuthServer() + "?username="+ RegRead("Username") + "&password=" + RegRead("Password") +"&site=" + getLoginSite())
    response = ParseJson(searchRequest.GetToString())
    if response.id<>invalid then
        m.response=response
        loadSchedule(screen)
    endif
    screen.close()
    'print "response: "; response
    return response 
End Function
'*************************************************************
'** get schedule json and build channel list and sports schedule
'*************************************************************
Function loadSchedule(screen) as void
    screen.SetTitle("Getting schedule")
    screen.ShowBusyAnimation()
    m.channels=getChannels()
    'create channel associative array
    m.channelArray=CreateObject("roArray", 51, true)
    m.categoryAsArray=CreateObject("roAssociativeArray")
    currTimeO=CreateObject("roDateTime")
    currTimeO.toLocalTime()
    'print "time is " + currTimeO.asDateStringNoParam() + " " + padTime(currTimeO.getHours()) + ":" + padTime(currTimeO.getMinutes())
    currTime=currTimeO.asSeconds()
    for i=1 to 51
        if m.channels.DoesExist(AnyToString(i)) then
            ch=m.channels[AnyToString(i)]
            'print ch
            videoclip = CreateObject("roAssociativeArray")
            videoclip.StreamBitrates = ["0"]
            videoclip.StreamUrls = getChannelURL(ch.channel_id)
            videoclip.StreamQualities = ["HD"]
            videoclip.StreamFormat = "hls"
            videoclip.Title = ch.name
            videoclip.HDPosterUrl="http://www.lyngsat-logo.com/logo/tv/" + m.channel_logos["c" + ch.channel_id]
            videoclip.SDPosterURL="http://www.lyngsat-logo.com/logo/tv/" + m.channel_logos["c" + ch.channel_id]
            'videoclip.HDPosterUrl= "http://smoothstreams.tv/schedule/includes/images/uploads/" + ch.img
            'videoclip.SDPosterUrl= "http://smoothstreams.tv/schedule/includes/images/uploads/" + ch.img
            'create show array
            for each sh in ch.items
                'dates/time from guide json need converting to local
                showEndTime=convertDateSeconds(sh.end_time)
                showStartTime=convertDateSeconds(sh.time)
                'print currTime; " : " showEndTime;
                if currTime<showEndTime
                    'print sh.name; " : "; sh.end_time;
                    'Now showing
                    if currTime>showStartTime
                        videoclip.shortDescriptionLine1="Now Showing"
                        videoclip.shortDescriptionLine2= sh.name
                    endif
                    videoShow=CreateObject("roAssociativeArray")
                    videoShow.StreamBitrates = ["0"]
                    videoShow.StreamUrls = getChannelURL(ch.channel_id)
                    videoShow.StreamQualities = ["HD"]
                    videoShow.StreamFormat = "hls"
                    videoShow.Title = sh.name
                    videoShow.Description=sh.description
                    videoShow.Categories=sh.category
                    videoShow.Live=true
                    videoShow.isHd=true
                    videoShow.HDBranded=true
                    videoShow.length=strToI(sh.runtime)*60
                    videoShow.ShortDescriptionLine1=sh.name
                    videoShow.ShortDescriptionLine2=convertDate(sh.time)
                    videoShow.time=sh.time
                    'replace space in network
                    r = CreateObject("roRegex", " ", "i")
                    sh.network=r.ReplaceAll(sh.network, "")
                    if m.channel_logos.DoesExist(sh.network)
                        logoUrl="http://www.lyngsat-logo.com/logo/tv/" + m.channel_logos[sh.network]
                    else
                        logoUrl="http://www.lyngsat-logo.com/logo/tv/" + m.channel_logos["c" + ch.channel_id]    
                    endif 
                    videoShow.HDPosterUrl=logoUrl
                    videoShow.SDPosterUrl=logoUrl 
                    'videoShow.HDPosterUrl= "http://smoothstreams.tv/schedule/includes/images/uploads/" + ch.img
                    'videoShow.SDPosterUrl= "http://smoothstreams.tv/schedule/includes/images/uploads/" + ch.img
                    if not m.categoryAsArray.DoesExist(sh.category) then
                        m.categoryAsArray.AddReplace(sh.category,[videoShow]) 
                    else
                        m.categoryAsArray[sh.category].push(videoShow)
                    endif
                endif
            end for
            m.channelArray.Push(videoclip)
        endif
    end for
    m.categoryArray=CreateObject("roArray", 10, true)
    for each cat in m.categoryAsArray
        m.categoryArray.Push(cat)
        Sort(m.categoryAsArray[cat],returnDate)
    end for
    Sort(m.categoryArray)
End Function
'*************************************************************
'** get authserver given current service setting
'*************************************************************
Function getAuthServer() as string
    serviceName = RegRead("Service")
    print serviceName
    if serviceName ="MyStreams & uSport" then
        return "http://smoothstreams.tv/login.php"
    else if serviceName = "Live247" then
        return "http://smoothstreams.tv/login.php"
    else if serviceName = "StarStreams" then
        return "http://starstreams.tv/t.php"
    else if serviceName = "MMA-TV / MyShout" then
        return "http://www.mma-tv.net/loginForm.php"
    else if serviceName = "None" then
        return "http://starstreams.tv/t.php"
    else
        return ""
    endif
End Function
'*************************************************************
'** get login site given current service setting
'*************************************************************
Function getLoginSite() as string
    serviceName = RegRead("Service")
    if serviceName ="MyStreams & uSport" then
        return "mystreams"
    else if serviceName = "Live247" then
        return "live247"
    else if serviceName = "StarStreams" then
        return "starstreams"
    else if serviceName = "MMA-TV / MyShout" then
        return "mma-tv"
    else
        return ""
    endif
End Function
'*************************************************************
'** get server url given current service setting
'*************************************************************
Function GetServerUrlByName() as string
    serverLocation=RegRead("Server Location")
    if serverLocation ="EU Random"
        return "dEU.SmoothStreams.tv"
    else if serverLocation = "EU Amsterdam"
        return "d88.SmoothStreams.tv"
    else if serverLocation = "EU London"
        return "d11.SmoothStreams.tv"
    else if serverLocation = "US East"
        return "dNAE.SmoothStreams.tv"
    else if serverLocation = "US West"
        return "dNAW.SmoothStreams.tv"
    else if serverLocation = "US All"
        return "dNA.SmoothStreams.tv"
    else if serverLocation = "Asia"
        return "dSG.SmoothStreams.tv"
    else
        'print "Invalid serverName passed to GetServerUrlByName"
        return ""
    endif
End Function
'*************************************************************
'** get http port given current service setting
'*************************************************************
Function GetServicePort() as string
    serviceName=RegRead("Service")
    if serviceName = "MMA-TV / MyShout" then
        port = "5545"
    else if serviceName = "StarStreams" then
        port = "39355"
    else if serviceName = "Live247" then
        port = "12935"
    else if serviceName = "MyStreams & uSport" then
        port = "29355"
    else
        'print "Invalid service name supplied to GetServicePort"
    endif
    return port
End Function
'*************************************************************
'** get channel url from channel number
'*************************************************************
Function getChannelUrl(channelNumber) as object
    urlArray=CreateObject("roArray",2,false)
    urlArray.push("http://" + GetServerUrlByName() + ":" + GetServicePort() + "/view/ch" + padChannelNumber(channelNumber) + "q1.stream/playlist.m3u8?u=" + AnyToString(m.response.id) + "&p=" + AnyToString(m.response.password))
    'urlArray.push("http://" + GetServerUrlByName() + ":" + GetServicePort() + "/view/ch" + padChannelNumber(channelNumber) + "q2.stream/playlist.m3u8?u=" + AnyToString(m.response.id) + "&p=" + AnyToString(m.response.password))
    return urlArray
End Function
'*************************************************************
'** get channels object from schedule json
'*************************************************************
Function getChannels() as object
    searchRequest = CreateObject("roUrlTransfer")
    searchRequest.SetURL("http://cdn.smoothstreams.tv/schedule/feed.json?timezone=UTC")
    response = ParseJson(searchRequest.GetToString())
    return response
End Function