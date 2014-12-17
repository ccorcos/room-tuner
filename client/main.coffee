
navigator.getUserMedia = navigator.getUserMedia or
                         navigator.webkitGetUserMedia or
                         navigator.mozGetUserMedia or
                         navigator.msGetUserMedia

window.requestAnimationFrame = window.requestAnimationFrame or
                         window.webkitRequestAnimationFrame or
                         window.mozRequestAnimationFrame or
                         window.msRequestAnimationFrame


microphoneError = (event) ->
    if event.name is "PermissionDeniedError" 
        alert "This app requires a microphone as input. Please adjust your privacy settings."

microphoneSuccess = (stream) ->
    initAudio(stream)

Template.main.rendered = ->
    if navigator.getUserMedia
        console.log "get microphone"
        navigator.getUserMedia {audio: true}, microphoneSuccess, microphoneError
    else
        alert "This app requires a microphone as input. Please try using Chrome or Firefox."

initAudio = (stream) ->

    canvasElement = document.getElementById("spectrum")
    width = 1000
    height = 400
    canvasElement.width = width
    canvasElement.height = height

    canvas = canvasElement.getContext("2d")
    context = new AudioContext()
    
    # Create an AudioNode from the stream (live input)
    sourceNode = context.createMediaStreamSource(stream)
    # Filter the audio to limit bandwidth to 4kHz before resampling,
    # by using a BiQuadFilterNode:
    filterNode = context.createBiquadFilter()
    filterNode.type = filterNode.LOWPASS
    filterNode.frequency.value = 4410
    filterNode.Q.value = 1.5
    filterNode.gain.value = 0

    # pipe the source throught the filter
    sourceNode.connect(filterNode)

    # set up the analyser
    analyser = context.createAnalyser()
    analyser.fftSize = 2048
    # analyser.fftSize = 1024
    # analyser.fftSize = 512
    # analyser.fftSize = 256

    # pipe through the analyser to the destination
    filterNode.connect(analyser)

    # comment this out to turn off microphone monitor
    # analyser.connect(context.destination)


    # create some buffers to store the fft data
    bufferLength = analyser.frequencyBinCount
    dataArray = new Uint8Array(bufferLength)

    # clear the canvas initially
    canvas.clearRect(0, 0, width, height)

    pinkNoise(context)

    # draw the spectrum on the canvas
    draw = ->

        # min = analyser.minDecibels
        # max = analyser.maxDecibels
        # range = max - min
        # console.log min, max
        # console.log dataArray

        drawVisual = requestAnimationFrame(draw)
        analyser.getByteFrequencyData(dataArray)

        canvas.fillStyle = 'rgb(0, 0, 0)';
        canvas.fillRect(0, 0, width, height);

        barWidth = (width / bufferLength) * 2.5

        x = 0
        for i in [0...bufferLength]
            barHeight = dataArray[i]/255*height

            canvas.fillStyle = 'rgb(255,50,50)';
            canvas.fillRect(x,height-barHeight,barWidth,barHeight);
            x += barWidth + 1;

    draw()

pinkNoise = (context) ->
    bufferSize = 4096
    b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0
    pinkNode = context.createScriptProcessor(bufferSize, 1, 1)
    pinkNode.onaudioprocess = (e) ->
        output = e.outputBuffer.getChannelData(0)
        for i in [0...bufferSize]
            white = Math.random() * 2 - 1
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            output[i] = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
            output[i] *= 0.11 # (roughly) compensate for gain
            b6 = white * 0.115926

    pinkNode.connect(context.destination)