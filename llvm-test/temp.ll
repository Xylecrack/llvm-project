define void @simple_function() {
entry:
  br label %block1
block1:
  %val1 = add i32 1, 2
  br label %block2
block2:
  %val2 = mul i32 %val1, 3
  br label %block3
block3:
  %val3 = sub i32 %val2, 4
  br label %block4
block4:
  ret void
}
