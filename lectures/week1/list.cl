class List {

  item:String;
  next:List;

  init(i:String, n:List):List {
    {
      item <- i;
      next <- n;
      self;
    }
  }; -- end of init()

  flatten():String {
    if (isvoid next) then
      item
    else
      item.concat(next.flatten())
    fi
  }; -- end of flatten()

}; -- end of class List

class Main inherits IO {

  main():Object {

    let hello:String      <- "Hello ",
        my_friend:String  <- " my friend!\n",
        nil:List,
        list:List <-
              (new List).init( hello,
                (new List).init( my_friend, nil ) ) 
    in
        out_string( list.flatten() )

  }; -- end of main

}; -- end of class





















