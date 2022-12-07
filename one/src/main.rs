use std::fs;

fn main() {
    let file_contents = fs::read_to_string("list.txt").expect("failed to read list.txt");
    let lines = file_contents.split("\n");

    let mut current = 0;
    let mut max = 0;

    for line in lines {
        match line.parse::<i32>() {
            Ok(value) => current += value,
            Err(_) => current = 0 //sorry not sorry
        }

        if current > max {
            max = current;
        }
    }
    
    println!("answer: {}", max);
}
