extends Node2D


# Declaración de escala
var tamano_real = Vector2(2000,2500) #expresado en metros
var tamano_pantalla = Vector2(1080,720) #expreasdo en pixeles #Tamaño real de ventana en pixeles
var escala = tamano_pantalla / tamano_real

# Declaracion de variables fisicas
var nave_masa =  500 #expresado en kg
var nave_velocidad = Vector2(0,1)
var nave_aceleracion 
var nave_posicion = Vector2()
var F_empuje = Vector2()
var F_lateral = Vector2()
var F_total = Vector2()
const gravedad = Vector2(0, 1 ) 

# Declaracion de variables auxiliares
var vivo = true
var mover = true
var asteroide2_dir
var asteroide2_vel
var asteroide_dir
var asteroide_vel
var rng = RandomNumberGenerator.new()
var t_delta
var Energia = 500
var timer= null
var animacion

func spawn_asteroides():
	asteroide_dir = Vector2(-150, rng.randi_range(300,700))
	asteroide_vel = Vector2(rng.randi_range(300,500),rng.randi_range(-30,30))
	asteroide2_dir= Vector2(rng.randi_range(2000,2500), rng.randi_range(1200,1500))
	asteroide2_vel= Vector2(-500,rng.randi_range(-150,150))

func _ready() -> void:
	$Perdiste.hide()
	$Ganaste.hide()
	rng.randomize()
	if Energia < 0:
		mover = false

	spawn_asteroides()
	
	nave_posicion = Vector2(rng.randi_range(200,800),0)
	nave_velocidad = Vector2(rng.randi_range(10,40),rng.randi_range(80,200))
	nave_aceleracion = Vector2(1,0)
	
	
	$SpriteNave.position = nave_posicion
	$Asteroides.position = asteroide_dir
	$Asteroides2.position = asteroide2_dir 

func Quieto():
	nave_velocidad = Vector2(0,0)
	asteroide2_vel= Vector2(0,0)
	asteroide_vel = Vector2(0,0)

func muerte():
	mover=false
	vivo=false
	Quieto()
	$SpriteNave.play("Dead")
	timer = Timer.new()
	timer.set_one_shot(true)
	timer.set_wait_time(3)
	timer.connect("timeout", Callable(self, "_on_TimerDeMuerte_timeout"))
	add_child(timer)
	timer.start()

#funciones para cambiar el color de las label 
func colores_combustible():
	if Energia > 300:
		$Energia.modulate = Color(0,250,0,1)
	elif Energia > 75:
		$Energia.modulate = Color(250,100,0,1)
	else:
		$Energia.modulate = Color(250,0,0,1)
func colores_velocidad():
	if nave_velocidad.y > 200:
		$Velocidad.modulate = Color(250,0,0,1)
	elif nave_velocidad.y > 100:
		$Velocidad.modulate = Color(250,100,0,1)
	elif nave_velocidad.y > 50:
		$Velocidad.modulate = Color(0,250,0,1)
	else:
		$Velocidad.modulate = Color(250,0,0,1)


func _physics_process(delta):
	#Label
	colores_combustible()
	colores_velocidad()
	$Energia.text = "Energia: " + str(Energia)
	$Velocidad.text="Velocidad: " + str(nave_velocidad.y)
	nave_posicion= $SpriteNave.position / escala
	
	# Deteccion entrada de usuario
	if Energia < 0: #cuando no tiene mas combustible ya no puede dirigir mas la nave y queda a la deriva
		mover = false
	if mover == true:
		if Input.is_action_pressed("ui_left"):
			$SpriteNave.play("Boost_Der")
			F_lateral= Vector2(-99999,0)
			Energia = Energia - 1
			
		elif Input.is_action_pressed("ui_right"):
			$SpriteNave.play("Boost_Izq")
			F_lateral= Vector2(99999,0)
			Energia = Energia - 1
		elif Input.is_action_pressed("ui_up"):
			$SpriteNave.play("Boost_Arriba")
			F_empuje= Vector2(0,-99999)
			Energia = Energia - 1
		elif Input.is_action_pressed("ui_down"):
			$SpriteNave.play("Boost_Bajar")
			F_empuje = Vector2(0,99999) 
			Energia = Energia - 1
		else:
			F_empuje= Vector2(0,0)
			F_lateral= Vector2(0,0)
			$SpriteNave.play("Idle")
			
	else:
		F_empuje=Vector2(0,0)
		F_lateral=Vector2(0,0)
		$SpriteNave.play("Idle")
		

# Deteccion de colisiones
	if $SpriteNave/AreaNave.overlaps_area($Asteroides_Q/Area2D) or $SpriteNave/AreaNave.overlaps_area($Bordes) or $SpriteNave/AreaNave.overlaps_area($Asteroides2_Q/Area2D) or $SpriteNave/AreaNave.overlaps_area($Asteroides/Area2D) or $SpriteNave/AreaNave.overlaps_area($Asteroides2/Area2D):
		$Perdiste.show()
		muerte()
	if $Asteroides/Area2D.overlaps_area($Bordes):
		spawn_asteroides()


	if $SpriteNave/AreaNave.overlaps_area($Pista/Area2D):
		if nave_velocidad.y < 200 and nave_velocidad.x < 200 and vivo == true:
			$Ganaste.show()
			mover=false
			Quieto()
			timer = Timer.new()
			timer.set_one_shot(true)
			timer.set_wait_time(3)
			timer.connect("timeout", Callable(self, "_on_TimerDeMuerte_timeout"))
			add_child(timer)
			timer.start()
		else: 
			$Perdiste.show()
			muerte()
			
# Calculos fisicos de movimiento
	F_total = F_empuje + F_lateral #La suma de todas las fuerzas
	nave_aceleracion = F_total / nave_masa + gravedad # La segunda ley de newton. F = Maza x Aceleracion
	nave_velocidad = nave_velocidad + nave_aceleracion * delta # velocidad = Aceleracion x el tiempo
	nave_posicion = nave_posicion + (nave_velocidad * delta) + (1/2 * nave_aceleracion) * pow(delta, 2) #Aca se acutalizaz la posicion.
	
	asteroide_dir = asteroide_dir + asteroide_vel * delta
	asteroide2_dir = asteroide2_dir + asteroide2_vel * delta
	
	# Renderizado
	$SpriteNave.position= nave_posicion * escala
				#asteroide1
	$Asteroides.position = asteroide_dir * escala
	$Asteroides.rotation_degrees = $Asteroides.rotation_degrees + 0.2
				#asteroide2
	$Asteroides2.position = asteroide2_dir * escala
	$Asteroides2.rotation_degrees = $Asteroides.rotation_degrees + 0.6
	
	#$Nave.position= nave_posicion * escala


func _on_TimerDeMuerte_timeout():
	get_tree().change_scene_to_file("res://Menu.tscn") 


func _on_texture_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Escenas/Main.tscn")
