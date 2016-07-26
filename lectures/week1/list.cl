class Main inherits IO {

  main():Object {

    let hello:String      <- "Hello ",
        my_friend:String  <- " my friend!\n"
    in
        out_string( hello.concat( my_friend ) )

  }; -- end of main

}; -- end of class