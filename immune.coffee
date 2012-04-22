class Immune
  constructor: (@doc, @win) ->
    @canvas  = @doc.getElementById("game_canvas")
    @context = @canvas.getContext("2d")
    @buttons =
      start: @doc.getElementById("start")
      pause: @doc.getElementById("pause")

    # Entities
    @bullets        = []
    @germs          = []
    @powerups       = []
    @activePowerUps = []

    @resource = {}

    # Status
    @status =
      sickness: 0
      score   : 0
      freeze: false
      activeFreezePowerUp: null
      frame: 0

    @buttons.start.onclick = @play
    @buttons.pause.onclick = @pause

    @key = new Key
    @win.onkeyup = (e) =>
      @key.onKeyUp e
    @win.onkeydown = (e) =>
      @key.onKeyDown e

    @defender = new Defender( @canvas.width / 2, @canvas.height - 50 )

    @loadResources =>
        @buttons.start.disabled = false
        @showTitleScreen()

  loadResources: ( playCallback ) ->
    imageCount = 0
    audioCount = 0

    images = [
      'img/germ.png',   'img/bg.png',     'img/vitamin.png',
      'img/shield.png', 'img/freeze.png', 'img/defender.png',
      'img/giant_germ.png'
    ]
    audios = [
      'sfx/shoot.ogg', 'sfx/explode.ogg', 'sfx/damage.ogg',
      'sfx/absorb.ogg', 'sfx/powerup.ogg', 'bg.ogg'
    ]

    finished = false;

    @loading imageCount + audioCount, images.length + audios.length

    # Just in case things take too long
    setTimeout ->
      if !finished
        playCallback();
        finished = true
    , 10000

    resourceOnLoad = (type) =>
      # firefox calls onload over and over again, even once things are loaded
      return if finished

      if type == 'image'
        imageCount++
      if type == 'audio'
        audioCount++

      @loading( imageCount + audioCount, images.length + audios.length );

      if imageCount == images.length and audioCount == audios.length
        if !finished
          playCallback()
        finished = true

    for imageName in images
      img = new Image()
      img.src = imageName
      img.addEventListener 'load', -> resourceOnLoad('image')
      @resource[imageName] = img

    for audioName in audios
      sound = new Audio()
      sound.src = audioName
      sound.addEventListener 'canplaythrough', -> resourceOnLoad('audio')
      @resource[audioName] = sound

  resetCanvas: ->
    @canvas.width = @canvas.width

  loading: (cur, total) ->
    @resetCanvas();

    msg = "Loading (#{cur}/#{total})..."

    @context.font = "bold 12px sans-serif"

    @context.textAlign = "center"
    @context.textBaseline = "middle"
    @context.fillText msg, @canvas.width - @canvas.width / 2, @canvas.height - @canvas.height / 2

  showTitleScreen: ->
    @resetCanvas();

    @context.drawImage @resource['img/bg.png'], 0, 0
    @context.fillStyle = 'rgba(0,0,0,.7)'
    @context.fillRect 0, 0, @canvas.width, @canvas.height

    @context.fillStyle = 'white'
    @context.font = 'bold 36px sans-serif'
    @context.textAlign = 'left'
    @context.fillText "Immune", 250, 60

    @context.font = 'bold 16px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "You're the defense!", 130, 50

    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'right'
    @context.fillText "You", 130, 70

    @context.drawImage @resource['img/defender.png'], 140, 60

    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'right'
    @context.fillText "Attack Ray", 130, 90

    @context.fillStyle = 'black'
    @context.fillRect 150, 82, 4, 10

    @context.fillStyle = 'white'
    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'right'
    @context.fillText "Absorption Ray", 130, 110

    @context.fillStyle = 'orange'
    @context.fillRect 150, 102, 4, 10

    @context.fillStyle = 'white'
    @context.font = 'bold 16px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "Destroy the germs!", 130, 150

    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'right'
    @context.fillText "Germ", 130, 170

    @context.drawImage @resource['img/germ.png'], 0, 0, 10 , 10, 140, 160, 10, 10

    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'right'
    @context.fillText "Super Germ", 130, 190

    @context.drawImage @resource['img/giant_germ.png'], 0, 0, 20 , 20, 140, 180, 20, 20

    @context.fillStyle = 'white'
    @context.font = 'bold 16px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "Power Up!", 130, 230

    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'right'
    @context.fillText "Germ Freeze", 130, 250

    @context.drawImage @resource['img/freeze.png'], 0, 0, 10 , 10, 140, 240, 10, 10

    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'right'
    @context.fillText "Shield", 130, 270

    @context.drawImage @resource['img/shield.png'], 0, 0, 10 , 10, 140, 260, 10, 10

    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'right'
    @context.fillText "Health", 130, 290

    @context.drawImage @resource['img/vitamin.png'], 0, 0, 10 , 10, 140, 280, 10, 10

    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'left'
    @context.fillText "Left and Right arrow keys move.", 250, 100
    @context.fillText "Press Up to fire attack. Press Down to fire absorb ray.", 250, 120

    @context.fillText "Hit power-ups with absorb rays to use them.", 250, 150
    @context.fillText "Destory the germs, don't hit them with your absorb ray!", 250, 170

    @context.fillText "Super germs cause more sickness.", 250, 200
    @context.fillText "Germs that get passed you will cause you to get sick.", 250, 220

    @context.font = 'bold 16px sans-serif'
    @context.textAlign = 'left'
    @context.fillText "Press Start to play!", 250, 280

  showPauseScreen: ->
    @context.fillStyle = 'rgba(0,0,0,.7)'
    @context.fillRect 0, 0, @canvas.width, @canvas.height

    @context.fillStyle = 'white'
    @context.font = 'bold 48px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "Paused", @canvas.width / 2, 125

  drawFrame: ->
    @resetCanvas()

    @status.frame++

    @context.drawImage @resource['img/bg.png'], 0, 0

    damage = @drawGerms(@bullets, @activePowerUps, @resource)
    @drawPowerUps(@bullets, @resource)
    @drawActivePowerUps(@bullets)

    @drawBullets()
    @defender.move(@canvas, @key, @bullets, @resource)
    @defender.draw(@context, @resource)

    if !@status.freeze
      @spawnGerms()
      @spawnPowerUps()
    else
      @context.fillStyle = 'purple'
      @context.font = 'bold 12px sans-serif'
      @context.textAlign = 'left'
      @context.fillText 'GERM FREEZE', 80, 42

    @drawStatus()

    if @status.sickness > 99
      @gameOver()
    else if damage
      @context.fillStyle = 'red'
      @context.fillRect 0, 0, @canvas.width, @canvas.height
      @resource['sfx/damage.ogg'].play()

  gameOver: ->
    @over = true
    clearInterval @frameInterval
    @frameInterval = null

    @context.fillStyle = 'rgba(0,0,0,.7)'
    @context.fillRect 0, 0, @canvas.width, @canvas.height

    @context.fillStyle = 'white'
    @context.font = 'bold 48px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "Oh no! Now you're sick!", @canvas.width / 2, 125

    @context.fillStyle = 'white'
    @context.font = 'bold 36px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "Score: " + @status.score, @canvas.width / 2, 200

    @context.fillStyle = 'white'
    @context.font = 'bold 24px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "(Hope you feel better.)", @canvas.width / 2, 250

  drawStatus: ->
    @context.fillStyle = 'rgba(0,0,0,.5)'
    @context.fillRect 0, 25, 75, 24

    @context.fillStyle = 'white'
    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'left'
    @context.fillText "Score: " + @status.score, 5, 42

    @context.fillStyle = 'rgba(0,0,0,.5)'
    @context.fillRect @canvas.width, 25, -100, 24

    @context.fillStyle = 'white'
    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'right'
    @context.fillText 'Sickness: ' + @status.sickness + '%', @canvas.width - 5, 42

  spawnGerms: ->
    if Math.random() < 0.02
      randX = Math.ceil (Math.random() * (@canvas.width - 100)) + 50
      if Math.random() < 0.8 and @status.frame < 3500
        @germs.push( new Germ randX, 0 );
      else
        @germs.push( new GiantGerm randX, 0 );

  spawnPowerUps: ->
    if Math.random() < 0.005
      randX = Math.ceil (Math.random() * (@canvas.width - 100)) + 50
      spawnType = Math.random()
      if spawnType < 0.4
        @powerups.push( new FreezeBomb randX, 0 );
      else if spawnType < 0.7
        @powerups.push( new Shield randX, 0 );
      else
        @powerups.push( new Vitamin randX, 0 );

  drawGerms: (bullets, powerups, resource) ->
    toCleanUp = [];
    damage    = false

    if @germs.length > 0
      for germIndex in [ 0 .. @germs.length - 1 ]
        germ = @germs[germIndex]
        germ.move(@context) if !@status.freeze
        germ.draw(@context, resource)

        bulletHit  = germ.isHit(bullets)
        powerUpHit = germ.isHit(powerups)
        if bulletHit.hit
          if bulletHit.absorb
            germ.health = 0
            @status.sickness = @status.sickness + germ.damage
            damage = true
          else
            germ.health--
            @status.score++
            if germ.health < 1
              resource['sfx/explode.ogg'].play()
          toCleanUp.push germIndex if germ.health < 1
        else if powerUpHit.hit
          toCleanUp.push germIndex
          powerUpHit.item.takeDamage(germ.damage)
          resource['sfx/explode.ogg'].play()
        else if germ.isOffscreen(@canvas)
          @status.sickness = @status.sickness + germ.damage
          damage = true
          toCleanUp.push germIndex

      for germIndex in toCleanUp
        @germs.splice germIndex, 1

    return damage

  drawPowerUps: (bullets, resource) ->
    toCleanUp = [];

    if @powerups.length > 0
      for powerupIndex in [ 0 .. @powerups.length - 1 ]
        powerup = @powerups[powerupIndex]
        powerup.move(@context)
        powerup.draw(@context, resource)

        powerupHit = powerup.isHit(bullets)
        if powerupHit.hit
          toCleanUp.push powerupIndex
          if powerupHit.absorb
            powerup.activate(@canvas, @status, resource)
            @activePowerUps.push powerup
          else
            resource['sfx/explode.ogg'].play()
        else if powerup.isOffscreen(@canvas)
          toCleanUp.push powerupIndex

      for powerupIndex in toCleanUp
        @powerups.splice powerupIndex, 1

  drawActivePowerUps: (germs) ->
    toCleanUp = [];

    if @activePowerUps.length > 0
      for powerUpIndex in [ 0 .. @activePowerUps.length - 1 ]
        powerup = @activePowerUps[powerUpIndex]
        powerup.draw @context, @resource
        if powerup.health < 1
          toCleanUp.push powerUpIndex

      for powerUpIndex in toCleanUp
        @activePowerUps.splice powerUpIndex, 1

  drawBullets: ->
    toCleanUp = [];

    if @bullets.length > 0
      for bulletIndex in [ 0 .. @bullets.length - 1 ]
        bullet = @bullets[bulletIndex]
        bullet.move(@context)
        bullet.draw(@context)
        if bullet.usedUp()
          toCleanUp.push bulletIndex

      for bulletIndex in toCleanUp
        @bullets.splice bulletIndex, 1

  play: =>
    return if @frameInterval

    if @over
      location.reload()
    else
      @resource['bg.ogg'].addEventListener 'ended', =>
        @resource['bg.ogg'].play()
      @resource['bg.ogg'].play()

      @frameInterval =
        setInterval =>
          @drawFrame()
        , 20

  pause: =>
    if @frameInterval
      clearInterval @frameInterval
      @frameInterval = null
      @showPauseScreen()
    else
      @play()

# Inspired by http://nokarma.org/2011/02/27/javascript-game-development-keyboard-input/index.html
class Key
  pressed: {}

  codes:
    "LEFT": 37
    "UP": 38
    "RIGHT": 39
    "DOWN": 40
    "SPACE": 32

  isDown: (keyCode) =>
    return @pressed[keyCode]

  onKeyDown: (event) =>
    @pressed[event.keyCode] = true

  onKeyUp: (event) =>
    delete @pressed[event.keyCode]

class Germ
  constructor: (@x, @y) ->
    @speed  = 1
    @width  = 10
    @height = 10
    @damage = 5
    @health = @baseHealth = 1
    @frame  = 0

  draw: (context, resource)->
    offset = if @frame <= 4 then 1 else 0
    context.drawImage resource['img/germ.png'], 10 * offset, 0, 10 , 10, @x, @y, @width, @height

  move: ->
    @y = @y + @speed;
    if @frame < 9 then @frame++ else @frame = 0;

  isOffscreen: (canvas) -> if @y > canvas.height then true else false

  isHit: (items) ->
    for item in items
      if ( @x <= item.x + item.width and
           @x + @width >= item.x and
           @y <= item.y + item.height and
           @y + @height >= item.y )
        item.hitSomething = true
        return { hit: true, absorb: item.absorb, item: item }
    return { hit: false }

class GiantGerm extends Germ
  constructor: (@x, @y) ->
    @speed = 0.5
    @width = 20
    @height = 20
    @damage = 30
    @health = @baseHealth = 15

  draw: (context, resource)->
    offset = if @frame <= 4 then 1 else 0
    context.drawImage resource['img/giant_germ.png'], 20 * offset, 0, 20 , 20, @x, @y, @width, @height
    context.fillStyle = 'red'
    if @health < @baseHealth
      healthWidth = @width * @health / @baseHealth
      context.fillRect @x, @y, healthWidth, 5

class PowerUp extends Germ
  constructor: (@x, @y) ->
    @speed = 1
    @width = 10
    @height = 10
    @damage = 15

  takeDamage: (damage) ->
    @health = @health - damage
    @height = @height - 2

  draw: (context) ->
    context.fillStyle = @color
    context.fillRect @x, @y, @width, @height

class Shield extends PowerUp
  color: 'blue'

  activate: (canvas, status, resource) ->
    resource['sfx/powerup.ogg'].play()
    @width = canvas.width
    @x = 0
    @health = 15

  draw: (context, resource)->
    offset = if @frame <= 4 then 1 else 0
    context.drawImage resource['img/shield.png'], 10 * offset, 0, 10 , 10, @x, @y, @width, @height

class Vitamin extends PowerUp
  color: 'red'
  healing: 10

  activate: (canvas, status, resource) ->
    resource['sfx/powerup.ogg'].play()
    if status.sickness - @healing > 0
      status.sickness = status.sickness - @healing
    else
      status.sickness = 0
    @health = 0

  draw: (context, resource)->
    offset = if @frame <= 4 then 1 else 0
    context.drawImage resource['img/vitamin.png'], 10 * offset, 0, 10 , 10, @x, @y, @width, @height

class FreezeBomb extends PowerUp
  freezeTimeout: null
  color: 'purple'

  cancelFreeze: ->
    clearTimeout @freezeTimeout
    @health = 0

  activate: (canvas, status, resource) ->
    resource['sfx/powerup.ogg'].play()
    status.freeze = true

    if status.activeFreezePowerUp
      status.activeFreezePowerUp.cancelFreeze()

    status.activeFreezePowerUp = @
    @freezeTimeout =
      setTimeout =>
        status.freeze = false
        status.activeFreezePowerUp = null
        @health = 0
      , 3000

  draw: (context, resource)->
    if @freezeTimeout
      context.drawImage resource['img/freeze.png'], 10, 0, 10 , 10, @x, @y, @width, @height
    else
      context.drawImage resource['img/freeze.png'], 0, 0, 10 , 10, @x, @y, @width, @height

class Defender
  constructor: (@x, @y) ->
    @speed  = 2
    @width  = 24
    @height = 15
    @cooldown = false

  draw: (context, resource)->
    context.drawImage resource['img/defender.png'], @x, @y

  move: (canvas, key, bullets, resource) ->
    if key.isDown(key.codes.LEFT) and @x - @speed >= 0
      @x = @x - @speed
    if key.isDown(key.codes.RIGHT) and @x + @speed <= canvas.width - @width
      @x = @x + @speed
    if key.isDown(key.codes.UP)
      @fire(bullets, resource)
    if key.isDown(key.codes.DOWN)
      @absorb(bullets, resource)

  fire: (bullets, resource) ->
    return if @cooldown
    resource['sfx/shoot.ogg'].play()
    bullets.push(new Bullet @x + @width / 2, @y)
    @cooldown = true
    setTimeout =>
      @cooldown = false
    , 100

  absorb: (bullets, resource) ->
    return if @cooldown
    resource['sfx/absorb.ogg'].play()
    bullets.push(new AbsorbBullet @x + @width / 2, @y)
    @cooldown = true
    setTimeout =>
      @cooldown = false
    , 100

class Bullet
  constructor: (@x, @y) ->
    @speed = 3
    @width = 4
    @height = 10
    @hitSomething = false

  draw: (context)->
    context.fillStyle = 'black'
    context.fillRect @x - @width / 2, @y, @width, @height

  move: ->
    @y = @y - @speed;

  usedUp: ->
    if @isOffscreen() or @hitSomething then true else false

  isOffscreen: -> if @y < 0 then true else false

class AbsorbBullet extends Bullet
  absorb: true

  draw: (context)->
    context.fillStyle = 'orange'
    context.fillRect @x - @width / 2, @y, @width, @height

window.onload = ->
  immune = new Immune window.document, window
